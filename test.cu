#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <time.h>
#include "block.cu"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <tuple>

using namespace std;

#define TILE_WIDTH 16

void matgen(float* a, int x, int y)
{
    int i, j;
    for (i = 0; i < x; i++)
    {
        for (j = 0; j < y; j++)
        {
            a[i * x + j] = (float)rand() / RAND_MAX + (float)rand()*2 / (RAND_MAX);
        }
    }
}

template<typename Dtype>
void print_tensor(tensor<Dtype>* Ts){
    for(int i=0;i<Ts->batch;i++){
        for(int j=0;j<Ts->channels;j++){
            for(int k=0;k<Ts->height;k++){
                for(int t=0;t<Ts->width;t++){
                    printf("%f ",Ts->data[i*(Ts->channels*Ts->width*Ts->height)+j*(Ts->width*Ts->height)+k*Ts->width+t]);
                }
                printf("\n");
            }
            printf("\n");
        }
        printf("\n");
    }
}

int main()
{
    printf("Test start!\n");

    int x = 16;
    int y = 16;
//    int z = 1024;

    float *M = (float*)malloc(sizeof(float)*x * y);

    srand(0);
    matgen(M, x, y);			//产生矩阵M
    printf("M ok\n");
    double timeStart, timeEnd;	//定义时间，求时间差用
    timeStart = clock();
    auto *A=new tensor<float>(M,8,8,2,2);

    print_tensor<float>(A);

    tensor<float>* B;
    //MatrixMultiplication_CUDA(M, N, Pg, x, y, z, gamma);			//GPU上计算
    tuple<int,int> *kernel=new tuple<int,int>{2,2};
    tuple<int,int> *padding=new tuple<int,int>{0,0};
    tuple<int,int> *stride=new tuple<int,int>{1,1};
    tuple<int,int> *dialations=new tuple<int,int>{1,1};

    /// ====== Test MaxPooling ======
//    printf("before pooling\n");
//    maxpooling2d<float> mxp{*kernel, *padding, *stride};
//    printf("mxp ok\n");
//    mxp.forward(A,B);

    /// ====== Test Convolution ======
    printf("before conv\n");
    int in_channel=2, out_channel=4;
    float *W = (float*)malloc(sizeof(float)* in_channel* out_channel * get<0>(*kernel)*get<1>(*kernel));
    matgen(W, in_channel* out_channel, get<0>(*kernel)*get<1>(*kernel));
    float *Bias = (float*)malloc(sizeof(float)* out_channel);
    matgen(Bias, out_channel,1);

    conv2d<float> conv{2,4, W, Bias,*kernel, *dialations, *padding, *stride};
    printf("conv ok\n");
    conv.forward(A,B);

    printf("B: %d %d %d %d\n",B->height,B->width,B->channels,B->batch);
    print_tensor<float>(B);

    timeEnd = clock();

    free(M);

//    Try_GPU();
//    system("pause");
    return 0;
}