#include <ctime> 
#include <cstdlib> 
#include <iostream>
#include <string>
#include <cmath>
#include <vector>

class Pt
{
public:
	float x = 0;
	float y = 0;
	int group = 1;
};
__global__ void setFalse(bool*& Changed, int dsize);
__device__ float dist(const Pt& p1, const Pt& p2);
__global__ void Group_find(Pt*& data, int dsize, Pt* dev_ctrs, bool*& moved);
__global__ void Moved_find(bool* moved, int dsize, bool* dev_isMoved);
__global__ void Group_update(Pt*& data, int dsize, float* sums, int* cnts);

int main()
{
	unsigned seed = time(0);
	srand(seed);

	int dsize=10;
	printf("enter data size  ");
	scanf("%d", &dsize);
	const int gsize = dsize/2;
	const int m1 = 0, n1 = gsize;
	const int m2 = n1+1, n2 = dsize;

	Pt expected1, expected2;
	float xsum = 0, ysum = 0;

	Pt* data;
	cudaMallocManaged( &data, dsize * sizeof(Pt) );
	bool* moved;
	cudaMallocManaged( &moved, dsize * sizeof(bool) );

	int blockSize = 1024;
	int blockNum = (dsize + blockSize - 1) / blockSize;

	Pt* dataTemp  = new Pt[dsize];
	for(int i = 0; i < gsize; ++i)
	{
		Pt p;
		p.x = m1 + rand() % (n1 - m1);
		xsum += p.x;
		p.y = m1 + rand() % (n1 - m1);
		ysum += p.y;
		dataTemp[i]=p;
	}
	expected1.x = xsum/gsize;
	expected1.y = ysum/gsize;


	xsum = 0, ysum = 0;
	for(int i = 0; i < gsize; ++i)
	{
		Pt p;
		p.x = m2 + rand() % (n2 - m2);
		xsum += p.x;
		p.y = m2 + rand() % (n2 - m2);
		ysum += p.y;
		dataTemp[i + gsize]=p;
	}
	expected2.x = xsum/gsize;
	expected2.y = ysum/gsize;
	

	cudaMemcpy(data,dataTemp, dsize * sizeof( Pt ), cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();

	Pt* ctrs = new Pt[2]; 
	ctrs[0].x = m1 + rand() % (n2-m1);
	ctrs[0].y = m1 + rand() % (n2-m1);
	ctrs[1].x = m1 + rand() % (n2-m1);
	ctrs[1].y = m1 + rand() % (n2-m1);

	Pt* dev_ctrs;
	cudaMallocManaged(&dev_ctrs, 2 * sizeof(Pt));
	cudaMemcpy(dev_ctrs, ctrs, 2 * sizeof( Pt ), cudaMemcpyHostToDevice);

	float* sums = new float[4];
	for(int s = 0; s < 4; ++s) sums[s] = 0;
	float* dev_sums;
	cudaMallocManaged(&dev_sums, 4 * sizeof(float));

	int* cnts = new int[2];
	cnts[0] = 1; cnts[1] = 1;
	int* dev_cnts;
	cudaMallocManaged(&dev_cnts, 2 * sizeof(int));


	bool* isMoved = new bool[1]; 
	isMoved[0] = true;

	bool* dev_isMoved;
	cudaMallocManaged(&dev_isMoved, sizeof(bool));

	while( isMoved[0] )
	{
		printf("Center1 = ( %.2f, %.2f )\n", ctrs[0].x ,ctrs[0].y);
		printf("Center2 = ( %.2f, %.2f )\n", ctrs[1].x, ctrs[1].y);
		isMoved[0] = false;

		clock_t st = clock();
		setFalse<<<blockNum, blockSize>>>(moved, dsize);
		cudaDeviceSynchronize();
		Group_find<<<blockNum, blockSize>>>(data, dsize, dev_ctrs, moved);
		cudaDeviceSynchronize();
		cudaMemcpy(dev_isMoved, isMoved, sizeof( bool ), cudaMemcpyHostToDevice);

		Moved_find<<<1, 1>>>(moved, dsize, dev_isMoved);
		cudaDeviceSynchronize();
		cudaMemcpy(isMoved, dev_isMoved, sizeof( bool ), cudaMemcpyDeviceToHost);

		clock_t st2 = clock();
		clock_t st3 = 0;
		clock_t st4 = 0;
		if( isMoved[0] )
		{
			st3 = clock();
			cudaMemcpy(dev_sums, sums, 4 * sizeof( float ), cudaMemcpyHostToDevice);
			cudaMemcpy(dev_cnts, cnts, 2 * sizeof( int ), cudaMemcpyHostToDevice);

			Group_update<<<blockNum, blockSize>>>(data, dsize, dev_sums, dev_cnts);
			cudaDeviceSynchronize();

			cudaMemcpy(sums, dev_sums, 4 * sizeof( float ), cudaMemcpyDeviceToHost);
			cudaMemcpy(cnts, dev_cnts, 2 * sizeof( int ), cudaMemcpyDeviceToHost);
			st4 = clock();
			ctrs[0].x = sums[0] / cnts[0];
			ctrs[0].y = sums[1] / cnts[0];
			ctrs[1].x = sums[2] / cnts[1];
			ctrs[1].y = sums[3] / cnts[1];
		}
		clock_t st5 = clock();
		cudaMemcpy(ctrs,dev_ctrs, 2 * sizeof( Pt ), cudaMemcpyDeviceToHost);
	
	printf("\n Elapsed Time : %u ms \n", clock() - st5 + (st4 - st3) + (st2 - st));

	}
	
	printf("---Result---:\n");
	printf("Expected1 = ( %.2f, %.2f )\n",expected1.x, expected1.y);
	printf("Expected2 = ( %.2f, %.2f )\n", expected2.x, expected2.y);

	printf("random initial Center1 = ( %.2f, %.2f )" ,ctrs[0].x ,ctrs[0].y);
	printf("random initial Center2 = ( %.2f, %.2f )", ctrs[1].x, ctrs[1].y);

	cudaFree(&data);
	cudaFree(&moved);
	delete [] dataTemp;
	delete [] isMoved;
	cudaFree( &dev_isMoved);

	delete [] sums;
	cudaFree( &dev_sums);
	delete [] cnts;
	cudaFree( &dev_cnts);

}

__device__ float dist(const Pt& p1, const Pt& p2)
{
	float s = sqrt(pow((p1.x - p2.x), 2) + pow((p1.y - p2.y), 2));
	return s;
}

__global__ void setFalse(bool*& Changed, int dsize)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index < dsize)
	{
		Changed[index] = false;
	}
}

__global__ void Group_find(Pt*& data, int dsize, Pt* dev_ctrs, bool*& moved)
{
	int p = blockIdx.x * blockDim.x + threadIdx.x;

	if (p < dsize)
	{
		float d1 = dist(dev_ctrs[0], data[p]);
		float d2 = dist(dev_ctrs[1], data[p]);
		int oldGroup = data[p].group;

		if (d1 < d2)
			data[p].group = 1;
		else
			data[p].group = 2;

		if (data[p].group != oldGroup)
		{
			moved[p] = true;
		}
	}
}

__global__ void Moved_find(bool* moved, int dsize, bool* dev_isMoved)
{
	int index = 0;
	while (index < dsize && !dev_isMoved[0])
	{
		if (moved[index] == true) {
			dev_isMoved[0] = true;
		}
		index++;
	}
}

__global__ void Group_update(Pt*& data, int dsize, float* sums, int* cnts)
{

	int p = blockIdx.x * blockDim.x + threadIdx.x;

	if (p < dsize)
	{
		if (data[p].group == 1)
		{
			sums[0] += data[p].x; sums[1] += data[p].y;
			cnts[0]++;
		}
		else
		{
			sums[2] += data[p].x; sums[3] += data[p].y;
			cnts[1]++;
		}
	}
}
