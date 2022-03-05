# Khởi tạo struct lưu các thông tin của 1 node.
mutable struct node
    parent # Vị trí node cha
    e # Tập E(node) lưu phần mở rộng phổ biến của node
    ae # Là tập con của E(), lưu phần mở rộng có trạng thái là active
    t # Tập T()= transactions giao với tập E
    transactions # Tập các transactions chứa itemset
    r # Tập các extension có khả năng được chọn
    itemset 
    childs # Vị trí các node con của node
    active # Trạng thái active
    support
end

# Lưu thông tin dùng trong khi tạo ma trận, bao gồm itemset và support
mutable struct info
    itemset
    support
end

# Hàm đọc data (giống với Apriori)
function readData(fileName)
    f=open(fileName)
    data=readlines(f)
    dat=Vector{Vector{Int}}()
    for i in data
        push!(dat, sort([parse(Int, s) for s in split(i)]))
    end
    return dat
end

# Hàm tìm các transaction trong biến data có chứa itemset
function findTrans(itemset, data)
    # Sử dụng filter để lọc ra các biến thoả điều kiện
    return filter(x->itemset ⊆ x, data)
end

# Hàm tìm danh sách tất cả item trong data
function find_all_items(data)
    l=Vector{Int}()
    for i in data
        for j in i
            # Nếu item j không tồn tại trong l thì push vào
            if j in l
                continue
            end
            push!(l, j)
        end
    end
    return sort(l)
end

# Hàm tạo tập T từ tập E, itemset và biến data
function createT(data, e, itemset)
    t=[]
    for i in data
        # Chỉ xét những transaction có chứa itemset
        if itemset ⊆ i
            # Tìm phần giao giữa transaction đó và tập E
            temp = i ∩ e
            # Nếu phần giao < 2, nó không có khả năng tạo thêm node mới
            # nên sẽ được loại bỏ đi
            if length(temp)>=2
                push!(t, i ∩ e)
            end
        end
    end
    return t
end

# Hàm tạo ma trận từ tập E và T
function createMatrix(E, T)
    matrix=Vector{Vector{info}}()
    # Sử dụng 2 vòng lặp để tạo ma trận tam giác
    for i in 1:length(E)-1
        t=Vector{info}()
        for j in i+1:length(E)
            it = info([E[i], E[j]], 0)
            # Với mỗi cặp matrix[i][j] được tạo, tiến hành tìm support
            # của nó từ tập T
            for k in T
                if it.itemset ⊆ k
                    it.support+=1
                end
            end
            push!(t, it)
        end
        push!(matrix, t)
    end
    return matrix
end

# Hàm khởi tạo cây
function init_tree(all_item)
    tree=Vector{Vector{node}}()
    # Khởi tạo các thông số cơ bản từ tất cả item trong all_item
    n=node(-1, Int[], [], all_item, data, all_item, [], Int[], true, 0)
    push!(tree, [n])
    # Trả về node gốc của cây
    return tree
end

# Hàm thay đổi trạng thái active của node tree[i][j]
function set_active(tree, i, j)
    # Đầu tiên set trạng thái của tree[i][j] thành false
    tree[i][j].active=false
    flag=true
    # Tìm node cha của node đang xét
    parent=tree[i][j].parent
    # Xoá đi node đang xét khỏi tập AE của node cha
    tree[parent[1]][parent[2]].ae=filter(x->x ≠ tree[i][j].itemset[length(tree[i][j].itemset)], tree[parent[1]][parent[2]].ae)
    # Sử dụng vòng lặp để set trạng thái của node cha, node ông,...
    while flag
        flag=false
        act=false
        # Kiểm tra nếu tất cả con của node cha đều là inactive
        # thì node cha cũng sẽ là inactive
        for q in tree[parent[1]][parent[2]].childs
            if tree[parent[1]+1][q].active
                act=true
                break
            end
        end
        if act==false
            # Khi đó set active của node cha này thành false
            tree[parent[1]][parent[2]].active=false
            flag=true
            # Tìm node ông
            parent=tree[parent[1]][parent[2]].parent
            # Nếu node ông có loại là Int (=-1)
            # thì ta đã duyệt đến gốc cây, nên sẽ dừng vòng lặp
            if typeof(parent)==Int
                flag=false
            end
        end
    end
end

# Hàm khởi tạo level 2 của cây
function create_first_level(tree, data, minsup, all_item)
    # Tạo mảng tree2 lưu các node thuộc level2 của cây
    tree2=[]
    # Duyệt qua tất cả các item trong data
    for i in all_item
        # Với mỗi item, tìm các transaction chứa item đó
        trans=findTrans(i, data)
        # Nếu số lượng transaction (support) >= minsup
        # tiến hành tạo node mới với các thông số cơ bản
        if length(trans)>=minsup
            n = node([1, 1], [], [], [], trans, [], i, [], true, length(trans))
            # Thêm node đó vào tree2
            push!(tree2, n)
            # Thêm giá trị của node đang xét vào tập E và AE của ndoe gốc
            push!(tree[1][1].e, i)
            push!(tree[1][1].ae, i)
            # Thêm vị trí con cho node gốc
            push!(tree[1][1].childs, length(tree2))
        end
    end
    # Thêm level1 vào cây
    push!(tree, tree2)
    # Duyệt qua các node level2 để xác định tập R của từng node
    # tập R(P) sẽ là các phần tử trong E(Q) mà lớn hơn item cuối của itemset trong P,
    # với Q là node cha của R
    for i in 1:length(tree[2])
        for j in tree[1][1].e
            if j > tree[2][i].itemset
                push!(tree[2][i].r, j)
            end
        end
        # Nếu R = rỗng, node không thể mở rộng nữa nên set active thành false
        if tree[2][i].r==[]
            set_active(tree, 2, i)
        end
    end
end

# Hàm tìm cha cho 1 node vừa khởi tạo
function findParent(tree, it, k, i)
    # Duyệt qua tất cả con của node ông của node vừa tạo,
    # node nào có item cuối = item đầu của node thì đó sẽ là cha
    for j in tree[k][i].childs
        if tree[k+1][j].itemset[length(tree[k+1][j].itemset)]==it[1]
            # trả về index của cha trong level =level node đang xét -1
            return j
        end
    end
end

# Hàm thực hiện thuật toán
function tree_projection(data, minsup)
    # Chuyển minsup về dạng số nguyên
    minsup_num=ceil(minsup*length(data)/100)
    # Tìm tất cả item trong data
    all_item=find_all_items(data)
    # Khởi tạo cây
    tree=init_tree(all_item)
    # Xây dựng level 1 của cây
    create_first_level(tree, data, minsup_num, all_item)
    k=2
    # Dùng vòng lặp để xây dựng từ level2 trở đi
    while tree[1][1].active
        # Khai báo mảng lv để lưu các node tại level k+1 của cây
        lv=[]
        # Duyệt qua các node ở level k-1
        for i in 1:length(tree[k-1])
            # Nếu node inactive thì bỏ qua
            if !tree[k-1][i].active
                continue
            end
            # Không thì tìm tập T của node đó
            tree[k-1][i].t = createT(tree[k-1][i].transactions, tree[k-1][i].e, tree[k-1][i].itemset)
            # Rồi xây dựng ma trận tương ứng
            matrix=createMatrix(tree[k-1][i].e, tree[k-1][i].t)
            # Duyệt qua từng vị trí trong ma trận
            for j in matrix
                for h in j
                    # Nếu vị trí bất kỳ có support thoả yêu cầu thì tiến hành thêm node mới
                    if h.support>=minsup_num
                        # Tìm itemset của node P bằng cách lấy hợp giữa node đang xét và itemset của
                        # vị trí đang xét
                        p = sort(tree[k-1][i].itemset ∪ h.itemset)
                        # Gọi hàm tìm vị trí node cha cho node sắp được tạo
                        parent=findParent(tree, h.itemset, k-1, i)
                        # Tạo node, gọi hàm findTrans tìm transactions chứa itemset của node mới này
                        n = node([k, parent], [], [], [], findTrans(p, tree[k][parent].transactions)
                        , [], p, [], true, h.support)
                        # Thêm item cuối của itemset vào tập E và AE của node cha
                        push!(tree[k][parent].e, h.itemset[2])
                        push!(tree[k][parent].ae, h.itemset[2])
                        # Thêm node n vào level k+1
                        push!(lv, n)
                        # Thêm con cho node cha
                        push!(tree[k][parent].childs, length(lv))
                    end
                end
            end
        end
        # Thêm level k vào cây
        push!(tree, lv)
        # Tiến hành duyệt để điều chỉnh active của các node không có con ở level k-1
        for i in 1:length(tree[k-1])
            if tree[k-1][i].childs==[]
                set_active(tree, k-1, i)
            end
        end
        # Dùng vòng lặp để xây dựng tập R cho các node vừa tạo, quá trình tương tự 
        # hàm create_first_level
        for i in 1:length(tree[k+1])
            parent=tree[k+1][i].parent
            for j in tree[parent[1]][parent[2]].e
                if j > tree[k+1][i].itemset[length(tree[k+1][i].itemset)]
                    push!(tree[k+1][i].r, j)
                end
            end
            if tree[k+1][i].r==[]
                set_active(tree, k+1, i)
            end
        end
        k+=1
    end
    return tree
end

# Hàm ghi kết quả thu được vào file txt
function writeResult(tree, dataName)
    open("output_tree_"*dataName, "w") do f
        # Duyệt qua từng level của cây
        for i in 2:length(tree)
            # Duyệt qua từng node của level
            for j in tree[i]
                # Ghi thông tin itemset
                write(f, "[")
                for k in 1: length(j.itemset)
                    write(f, string(j.itemset[k]))
                    if k!=length(j.itemset)
                        write(f, ", ")
                    end
                end
                # Ghi thông tin support
                write(f, "]\t", string(j.support), "\n")
            end
        end
    end
end

println("Hay nhap vao ten tap du lieu can thuc hien")
println("VD: Nhap foodmart de thuc hien tren tap du lieu foodmart")
dataName=readline()
dataName*=".txt"
println("Hay nhap min support")
println("VD: 50 cho min support = 50%")
minsup=parse(Float64, readline())
data=readData(dataName)
writeResult(tree_projection(data, minsup), dataName)
println("Chuong trinh da chay xong!")
