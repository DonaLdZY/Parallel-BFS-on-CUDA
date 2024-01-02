#include<iostream>
#include<fstream>
#include<vector>
#include<time.h>
#include<stdlib.h>
#include<random>
#include<string>
using namespace std;
int main(){
    cout<<"-- generate a random graph --"<<endl;
    
    cout<<"File name :"<<endl;
    string file;
    cin>>file;
    file="data/"+file;
    cout<<"vertex size (max 100000):"<<endl;
    int n;
    cin>>n;
    n=min(max(n,0),100000);
    cout<<"expected edge size :"<<endl;
    int m,ct=0;
    cin>>m;
    m=min(max(m,0),n*(n-1)/2);

    random_device seed;//硬件生成随机数种子
	ranlux48 engine(seed());//利用种子生成随机数引擎
    uniform_int_distribution<> distrib(0, n*(n-1));//设置随机数范围，并为均匀分布
    vector<vector<int> > x(n);
    for (int i=0;i<n;i++){
        for (int j=0;j<i;j++){
            int tp=distrib(engine);
            if (tp<2*m){
                ct+=2;
                x[i].push_back(j);
                x[j].push_back(i);
            } 
        }
    }
    cout<<"real edge size: "<<ct<<endl;
    ofstream fout(file, ios::out);
    fout<<n<<' '<<ct<<'\n';
    for (int i=0;i<n;i++){
        ct+=x[i].size();
        fout<<x[i].size()<<' ';
        for (int j=0;j<x[i].size();j++){
            fout<<x[i][j]<<' ';
        }
        fout<<"\n";
    }
    fout.close();
}