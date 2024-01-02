import os
import filecmp
if __name__=="__main__":
    name1=input("result 1:")
    name2=input("result 2:")
    name1="result/"+name1+".txt"
    name2="result/"+name2+".txt"
    # 如果两边路径的头文件都存在，进行比较
    try:
        status = filecmp.cmp(name1, name2)
        # 为True表示两文件相同
        if status:
            print("files are the same")
        # 为False表示文件不相同
        else:
            print("files are different")
    # 如果两边路径头文件不都存在，抛异常
    except IOError:
        print("Error:"+ "File not found or failed to read")
