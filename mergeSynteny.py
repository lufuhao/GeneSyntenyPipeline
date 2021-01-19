#!/usr/bin/python3

import sys

def fun1(listdir):   
    dict1={}
    k=0
    for i in listdir:
        file=open(i)
        a=file.readline()
        a=a.strip()
        b=a.split("\t")
        for j in [b[0],b[1]]:
            if j[0:3] not in dict1:
                dict1[j[0:3]]=k
                k=k+1
        file.close()
    return dict1,k           #??{'A00': 0, 'B00': 1, 'D00': 2, 'E00': 3} 4

def fun2(dict1,k):
    if len(dict1)!=0:
        for i in dict1:
            if (k[0] in dict1[i])or(k[1] in dict1[i]):
                return i
                break
        else:
                return 0
    else:
        return 0
def fun3(listdir,out,dict1,k):
    dict2={}
    m=0
    list2=[]
    for i in listdir:
        file=open(i)
        for j in file:
            list1=["?"]*k
            a=j.strip()
            b=a.split("\t")
            index=fun2(dict2,b)
            if index==0:
                list1[dict1[b[0][0:3]]]=b[0]
                list1[dict1[b[1][0:3]]]=b[1]
                dict2[str(m)]=list1
                m+=1
            else:
                m1=dict2[index][dict1[b[0][0:3]]]
                m2=dict2[index][dict1[b[1][0:3]]]
                if m1!="?" and m1!=b[0]:
                     list2.append([dict2[index][dict1[b[0][0:3]]],b[0]])
                     dict2[index][dict1[b[0][0:3]]]="error"
                     dict2[index][dict1[b[1][0:3]]]=b[1]
                     #list2.append(b[0])
                elif m2!="?" and m2!=b[1]:
                     list2.append([dict2[index][dict1[b[1][0:3]]],b[1]])
                     dict2[index][dict1[b[0][0:3]]]=b[0]
                     dict2[index][dict1[b[1][0:3]]]="Error"
                     #list2.append(b[1])
                else :
                     dict2[index][dict1[b[0][0:3]]]=b[0]
                     dict2[index][dict1[b[1][0:3]]]=b[1]
        file1=open(out,"w")
        for i in dict2:
            s="\t".join(dict2[i])+"\n"
            file1.write(s)
        file1.close()
    for kk in list2:
        s="Error:inconsistene pairing "+"/".join(kk)+"\n"
        sys.stderr.write(s)

if __name__=="__main__":
    import sys
    input1=sys.argv[1:-1]
    out=sys.argv[-1]
    '''
    input1=["1.txt","2.txt","3.txt","4.txt"]
    out="out.txt"
    '''
    dict1,k=fun1(input1)
    fun3(input1,out,dict1,k)
