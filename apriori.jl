# Khởi tạo struct result để lưu một tập phổ biến,
# bao gồm 2 thông tin là item set của tập và support của tập đó
mutable struct result
    itemset
    support
end

# Hàm readData, dùng để đọc file có tên là fileName 
function readData(fileName)
    f=open(fileName)
    lines=readlines(f) # Đọc các dòng của file
    data=Vector{Vector{Int}}() # Khai báo biến lưu dữ liệu đọc vào
    # Duyệt qua từng dòng, tách các ký tự ra rồi ép kiểu và 
    # push vào data
    for i in lines 
        push!(data, sort([parse(Int, s) for s in split(i)]))
    end
    return data
end

# Hàm dùng để đếm support của 1 itemset trong data
function count_support(itemset, data)
    count=0
    # Sử dụng vòng lặp để duyệt, nếu có transaction nào
    # chứa itemset thì cộng count lên 1
    for i in data
        if itemset ⊆ i
            count+=1
        end
    end
    return count
end

# Hàm tìm tập C(k+1) từ tập F(k)
function nextC(lastf, nextlength)
    c=Vector{Vector{Int}}()
    s=size(lastf, 1)
    # Dùng 2 vòng lặp để duyệt các tổ hợp chập 2 của F(k)
    for i in 1:s
        for j in i+1:s
            flag=false
            # Khai báo biến tạm t lưu giá trị của 1 tổ hợp
            # Dùng phép hợp để gộp 2 itemset lại
            t = sort(lastf[i].itemset ∪ lastf[j].itemset)
            # Kiểm tra độ dài của t, chỉ giữ lại những tập
            # Có độ dài k+1
            if length(t)!=nextlength
                flag=true
            end
            if flag==false
                push!(c, t)
            end
        end
    end
    # Xoá đi các phần tử bị trùng trong C
    c=unique(c)
    return c
end

# Tạo F(k) từ C(k)
function createF(c, data, minsup)
    f=Vector{result}()
    # Duyệt qua từng phần tử của C
    for i in c
        # Tìm support của từng phần tử
        support=count_support(i, data)
        #Nếu support nào thoả thì thêm itemset và support tương ứng vào f
        if count_support(i, data)>=minsup
            push!(f, result(i, support))
        end
    end
    return f
end

# Hàm tìm tập C đầu tiên (tập C gồm 1 - element itemsets)
function firstC(data)
    c=Vector{Vector{Int}}()
    # Sử dụng 2 vòng lặp để duyệt qua từng item trong data
    for i in data
        for j in i
            # Nếu item chưa tồn tại trong C thì push vào
            if [j] in c
                continue
            end
            push!(c, [j])
        end
    end
    # Sắp xếp lại C
    return sort(c)
end

# Hàm thực hiện thuật toán Apriori
function apriori(data, minsup)
    # Chuyển giá trị minsup từ % sang số nguyên
    minsup_num=ceil(minsup*length(data)/100)
    # Tìm tập C đầu tiên
    c=firstC(data)
    fim=Vector{result}()
    k=1
    # Dùng vòng lặp để xây dựng các tập F, C đến khi C=[]
    while c!=[]
        k+=1
        f=createF(c, data, minsup_num)
        # Sau khi tạo được F(k) thì trộn vào cuối mảng fim lưu kết quả
        fim=vcat(fim, f)
        c=nextC(f, k)
    end
    return fim
end

# Hàm ghi kết quả thu được vào file txt
function writeResult(fi, dataName)
    open("output_apriori_"*dataName, "w") do f
        # Duyệt từng phần tử của mảng
        for i in fi
            # Ghi itemset của phần tử
            write(f, "[")
            for j in 1: length(i.itemset)
                write(f, string(i.itemset[j]))
                if j!=length(i.itemset)
                    write(f, ", ")
                end
            end
            # Ghi support của phần tử
            write(f, "]\t", string(i.support), "\n")
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
writeResult(apriori(data, minsup), dataName)
println("Chuong trinh da chay xong!")