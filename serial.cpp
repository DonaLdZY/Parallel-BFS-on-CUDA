#include<iostream>
#include<fstream>
#include<vector>
#include<time.h>
#include<stdlib.h>
#include<random>
#include<string>
#include<string.h>
#include<queue>
#include<chrono>
#include<stdio.h>
using namespace std;
int n,m;
void bfs_serial(int n,int m,int *index,int *edge,int *result){
    queue<int> bfs;
    bfs.push(0);
    while (!bfs.empty()){
        int x=bfs.front();
        bfs.pop();
        for (int i=index[x];i<index[x+1];i++){
            int y=edge[i];
            if (result[y]==-1){
                result[y]=result[x]+1;
                bfs.push(y);
            }
        }
    }
}
int main() {
    std::cout<<"File name :"<<std::endl;
    string file;
    cin>>file;
    string file_in="data/"+file;
    string file_out="result/serial_"+file;
    ifstream fin(file_in,ios::in);
    fin>>n>>m;
    int *index=new int[n+1]; //节点x的边的偏移量
    int *edge=new int[m+1]; //所有边
    index[0]=0;
    for (int i=0;i<n;i++){
        int xs;
        fin>>xs;
        index[i+1]=index[i]+xs;
        for (int j=0;j<xs;j++)
            fin>>edge[index[i]+j];
    }
    int *result=new int[n+1];
    for (int i=0;i<n;i++)
        result[i]=-1;
    result[0]=0;

    auto startTime = chrono::steady_clock::now();
    bfs_serial(n,m,index,edge,result);
    auto endTime = std::chrono::steady_clock::now();
    long duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
	printf("Elapsed time for Serial BFS : %li ms.\n", duration);

    ofstream fout(file_out,ios::out);
    fout<<n<<endl;
    for (int i=0;i<n;i++){
        fout<<result[i]<<endl;
    }
    delete []index;
    delete []edge;
    delete []result;
    fin.close();
    fout.close();
    return 0;
}
