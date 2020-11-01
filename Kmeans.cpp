#include <ctime> 
#include <cstdlib> 
#include <iostream>
#include <string>
#include <cmath>
#include <vector>
#include <time.h>

class Pt
{
public:
	float x = 0;
	float y = 0;
	int group = 0;
};

float dist(const Pt& p1, const Pt& p2);

int main()
{
	unsigned seed = time(0);
	srand(seed);

	int dsize = 10;
	printf("enter data Size ! ");
	scanf("%d", &dsize);
	const int gsize = dsize / 2;
	const int m1 = 0, n1 = gsize;
	const int m2 = n1 + 1, n2 = dsize;

	Pt expected1, expected2;
	float xsum = 0, ysum = 0;
	std::vector<Pt> data;

	for (int i = 0; i < gsize; ++i)
	{
		Pt p;
		p.x = m1 + rand() % (n1 - m1);
		xsum += p.x;
		p.y = m1 + rand() % (n1 - m1);
		ysum += p.y;
		data.push_back(p);
	}
	expected1.x = xsum / gsize;
	expected1.y = ysum / gsize;

	xsum = 0, ysum = 0;
	for (int i = 0; i < gsize; ++i)
	{
		Pt p;
		p.x = m2 + rand() % (n2 - m2);
		xsum += p.x;
		p.y = m2 + rand() % (n2 - m2);
		ysum += p.y;
		data.push_back(p);
	}
	expected2.x = xsum / gsize;
	expected2.y = ysum / gsize;

	Pt ctr1, ctr2;
	ctr1.x = m1 + rand() % (n2 - m1);
	ctr1.y = m1 + rand() % (n2 - m1);
	ctr2.x = m1 + rand() % (n2 - m1);
	ctr2.y = m1 + rand() % (n2 - m1);

	float d1 = 0, d2 = 0;

	bool isMoved = true;
	clock_t st = clock();
	while (isMoved)
	{

		printf("Center1 = ( %.2f, %.2f )\n", ctr1.x, ctr1.y);
		printf("Center2 = ( %.2f, %.2f )\n", ctr2.x, ctr2.y);
		
		isMoved = false;

		for (int p = 0; p < data.size(); ++p)
		{
			d1 = dist(ctr1, data[p]);
			d2 = dist(ctr2, data[p]);
			int oldGroup = data[p].group;

			if (d1 < d2)
				data[p].group = 1;
			else
				data[p].group = 2;

			if (data[p].group != oldGroup)
			{
				isMoved = true;
			}
		}
		if (isMoved)
		{
			float xsum1 = 0, ysum1 = 0, xsum2 = 0, ysum2 = 0;
			float cnt1 = 1, cnt2 = 1;
			for (auto p : data) //for( int p = 0; p < data.size(); ++p)
			{
				if (p.group == 1)
				{
					xsum1 += p.x; ysum1 += p.y;
					cnt1++;
				}
				else
				{
					xsum2 += p.x; ysum2 += p.y;
					cnt2++;
				}
			}
			ctr1.x = xsum1 / cnt1;
			ctr1.y = ysum1 / cnt1;
			ctr2.x = xsum2 / cnt2;
			ctr2.y = ysum2 / cnt2;
		}
	}

	printf("\n Elapsed Time : %u ms \n", clock() - st);
	printf("---Result---:\n");
	printf("random initialCenter1 (= ( %.2f, %.2f )\n", ctr1.x, ctr1.y);
	printf("random Center2 = ( %.2f, %.2f )\n", ctr2.x, ctr2.y);
	printf("Expected1 = ( %.2f, %.2f )\n",expected1.x,expected1.y);
	printf("Expected2 = ( %.2f, %.2f )\n", expected2.x, expected2.y);

}

float dist(const Pt& p1, const Pt& p2)
{
	float s = sqrt(pow((p1.x - p2.x), 2) + pow((p1.y - p2.y), 2));
	return s;
}
