#include<iostream>
#include<fstream>
#include<vector>
#include<time.h>
#include<stdlib.h>
#include<random>
#include<string>
#include<string.h>
#include<queue>
#include <chrono>
#include<stdio.h>
#include<cuda.h>
using namespace std;
int n,m;
#define THREADS_PER_BLOCK 32

__global__ void bfs_kernel(int n, int m, int *d_index, int *d_edge, int *d_result, bool *d_continue, int level) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if(index < n && d_result[index] == level) {
        for(int i = d_index[index]; i < d_index[index + 1]; i++) {
            int y = d_edge[i];
            if(d_result[y] == -1 || d_result[y] > d_result[index] + 1) {
                d_result[y] = d_result[index] + 1;
                *d_continue = true;
            }
        }
    }
}

void bfs_vertex_parallel(int n, int m, int *index, int *edge, int *result) {
    const int n_blocks=(n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;

    int *d_index, *d_edge, *d_result;
    bool h_continue, *d_continue;

    cudaMalloc((void**)&d_index, (n+1)*sizeof(int));
    cudaMalloc((void**)&d_edge, (m+1)*sizeof(int));
    cudaMalloc((void**)&d_result, (n+1)*sizeof(int));
    cudaMalloc((void**)&d_continue, sizeof(bool));

    cudaMemcpy(d_index, index, (n+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_edge, edge, (m+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_result, result, (n+1)*sizeof(int), cudaMemcpyHostToDevice);
    auto startTime = chrono::steady_clock::now();
    int level=0;
    do {
        h_continue = false;
        cudaMemcpy(d_continue, &h_continue, sizeof(bool), cudaMemcpyHostToDevice);
        bfs_kernel<<<n_blocks, THREADS_PER_BLOCK>>>(n, m, d_index, d_edge, d_result, d_continue,level);
        cudaDeviceSynchronize();
        cudaMemcpy(&h_continue, d_continue, sizeof(bool), cudaMemcpyDeviceToHost);
        level++;
    } while(h_continue);

    cudaMemcpy(result, d_result, (n+1)*sizeof(int), cudaMemcpyDeviceToHost);
    auto endTime = std::chrono::steady_clock::now();
	auto duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
	printf("Elapsed time for vertex_parallel BFS (without copying graph) : %li ms.\n", duration);

    cudaFree(d_index);
    cudaFree(d_edge);
    cudaFree(d_result);
    cudaFree(d_continue);
}

int main() {
    std::cout<<"File name :"<<std::endl;
    string file;
    cin>>file;
    string file_in="data/"+file;
    string file_out="result/vertex_parallel_"+file;
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
    bfs_vertex_parallel(n,m,index,edge,result);
    auto endTime = std::chrono::steady_clock::now();
    long duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
	printf("Elapsed time for vertex_parallel BFS (with graph copying) : %li ms.\n", duration);

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
