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

__global__ void bfs_kernel(int n, int m, int *d_index, int *d_edge, int *d_result, int h_cur_qsize, int * d_cur_q, int *d_nxt_qsize, int *d_nxt_q) {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    if(tid < h_cur_qsize) {
        int index=d_cur_q[tid];

        for(int i = d_index[index]; i < d_index[index + 1]; i++) {
            int y = d_edge[i];
            if(d_result[y] == -1 || d_result[y] > d_result[index] + 1) {
                d_result[y] = d_result[index] + 1;
                int nxt_qpos = atomicAdd(d_nxt_qsize, 1);
                d_nxt_q[nxt_qpos]=y;
            }
        }
    }
}

void bfs_task_parallel(int n, int m, int *index, int *edge, int *result) {
    const int n_blocks=(n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;

    int *d_index, *d_edge, *d_result;
    cudaMalloc((void**)&d_index, (n+1)*sizeof(int));
    cudaMalloc((void**)&d_edge, (m+1)*sizeof(int));
    cudaMalloc((void**)&d_result, (n+1)*sizeof(int));
    cudaMemcpy(d_index, index, (n+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_edge, edge, (m+1)*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_result, result, (n+1)*sizeof(int), cudaMemcpyHostToDevice);

    int *d_first_q, *d_second_q, *d_nxt_qsize;
    int h_cur_qsize=1;
    int zero=0;
    cudaMalloc((void **)&d_first_q, (n+1)*sizeof(int));
	cudaMalloc((void **)&d_second_q, (n+1)*sizeof(int));
	cudaMalloc((void **)&d_nxt_qsize, sizeof(int));

    cudaMemcpy(d_first_q, &zero, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_nxt_qsize, &zero, sizeof(int), cudaMemcpyHostToDevice);
    
    auto startTime = chrono::steady_clock::now();
    int level=0;
    while (h_cur_qsize){
        int *d_cur_q, *d_nxt_q;
        if (level % 2==0){
            d_cur_q = d_first_q;
            d_nxt_q = d_second_q;
        }
        else{
            d_cur_q = d_second_q;
            d_nxt_q = d_first_q;
        }
            
        bfs_kernel<<<n_blocks, THREADS_PER_BLOCK>>>(n, m, d_index, d_edge, d_result, h_cur_qsize, d_cur_q, d_nxt_qsize, d_nxt_q);
        cudaDeviceSynchronize();
        cudaMemcpy(&h_cur_qsize, d_nxt_qsize, sizeof(int), cudaMemcpyDeviceToHost);
        cudaMemcpy(d_nxt_qsize, &zero, sizeof(int), cudaMemcpyHostToDevice);
        level++;
    }

    cudaMemcpy(result, d_result, (n+1)*sizeof(int), cudaMemcpyDeviceToHost);
    auto endTime = std::chrono::steady_clock::now();
	auto duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
	printf("Elapsed time for task_parallel BFS (without copying graph) : %li ms.\n", duration);
    cudaFree(d_index);
    cudaFree(d_edge);
    cudaFree(d_result);
    cudaFree(d_first_q);
    cudaFree(d_second_q);
    cudaFree(d_nxt_qsize);
}

int main() {
    std::cout<<"File name :"<<std::endl;
    string file;
    cin>>file;
    string file_in="data/"+file;
    string file_out="result/task_parallel_"+file;
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
    bfs_task_parallel(n,m,index,edge,result);
    auto endTime = std::chrono::steady_clock::now();
    long duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
	printf("Elapsed time for task_parallel BFS (with graph copying) : %li ms.\n", duration);

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
