#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define min(a, b) a < b ? a : b;

enum { direct_map = 0, four_way = 1, fully = 2 };
enum { FIFO = 0, LRU = 1, my_policy = 2 };

typedef struct {
    bool valid;
    int tag;
} block;

int main(int argc, char *argv[])
{
    // parsing arguments
    if (argc < 2) {
        puts("Usage: cache [trace.txt] [trace.out]");
        exit(-1);
    }

    FILE *in = fopen(argv[1], "r");
    FILE *out = fopen(argv[2], "w");

    // get initial settings
    int cache_sz, block_sz, asso, policy;
    fscanf(in, "%d%d%d%d", &cache_sz, &block_sz, &asso, &policy);

    // setting up the cache
    int block_num, index_wid, off_wid, size;
    int index_mask;

    int *set_size;

    int *access_time, **set_acc_time;

    block *cache_direct, *cache_fully, **cache_four;

    switch (asso) {
    case direct_map:
        block_num = (cache_sz << 10) / block_sz;
        index_wid = log2(block_num);
        off_wid = log2(block_sz);

        index_mask = block_num - 1;

        cache_direct = calloc(block_num, sizeof(block));
        break;

    case fully:
        block_num = (cache_sz << 10) / block_sz;
        index_wid = 0;
        off_wid = log2(block_sz);
        size = 0;

        index_mask = 0;

        cache_fully = calloc(block_num, sizeof(block));
        access_time = calloc(block_num, sizeof(int));
        break;

    case four_way:
        block_num = (cache_sz << 10) / block_sz;
        index_wid = log2(block_num >> 2);
        off_wid = log2(block_sz);

        index_mask = (block_num >> 2) - 1;

        set_size = calloc(block_num >> 2, sizeof(int));
        cache_four = malloc(sizeof(block *) * (block_num >> 2));
        set_acc_time = malloc(sizeof(int *) * (block_num >> 2));

        for (int i = 0; i < (block_num >> 2); i++) {
            cache_four[i] = calloc(4, sizeof(block));
            set_acc_time[i] = calloc(4, sizeof(int));
        }
        break;
    }

    int time = 0;

#ifdef DEBUG
    printf("block_num: %d\nindex_wid: %d\nindex_mask: %d\n", block_num,
           index_wid, index_mask);
#endif

    // processing data
    unsigned int addr, index, tag;
    while (fscanf(in, "%x", &addr) != EOF) {
        index = (addr >> off_wid) & index_mask;
        tag = addr >> (index_wid + off_wid);

#ifdef DEBUG
        printf("index: %d\n", index);
#endif

        if (asso == direct_map) {
            if (cache_direct[index].valid && tag != cache_direct[index].tag)
                fprintf(out, "%d\n", cache_direct[index].tag);
            else
                fprintf(out, "-1\n");

            cache_direct[index].tag = tag;
            cache_direct[index].valid = true;
        } else if (asso == four_way) {
            bool found = false;
            int i;
            for (i = 0; i < set_size[index]; i++) {
                if (cache_four[index][i].tag == tag) {
                    found = true;
                    break;
                }
            }

            if (found) {
                set_acc_time[index][i] = time;
                fprintf(out, "-1\n");
            } else {
                if (i < 4) {
                    set_size[index] = min(set_size[index] + 1, 4);
                    set_acc_time[index][i] = time;
                    cache_four[index][i].tag = tag;
                    cache_four[index][i].valid = true;
                    fprintf(out, "-1\n");
                } else {
                    // search for replacement
                    int tar = 0, tar_time = set_acc_time[index][0];
                    for (int j = 0; j < set_size[index]; j++) {
                        if (policy == FIFO) {
                            if (tar_time < set_acc_time[index][j]) {
                                tar_time = set_acc_time[index][j];
                                tar = j;
                            }
                        } else if (policy == LRU) {
                            if (tar_time > set_acc_time[index][j]) {
                                tar_time = set_acc_time[index][j];
                                tar = j;
                            }
                        } else if (policy == my_policy) {
                            if (tar_time > set_acc_time[index][j]) {
                                tar_time = set_acc_time[index][j];
                                tar = j;
                            }
                        }
                    }
                    fprintf(out, "%d\n", cache_four[index][tar].tag);

                    set_acc_time[index][tar] = time;
                    cache_four[index][tar].tag = tag;
                    cache_four[index][tar].valid = true;
                }
            }

            time++;
        } else if (asso == fully) {
            bool found = false;
            int i;
            for (i = 0; i < size; i++) {
                if (cache_fully[i].tag == tag) {
                    found = true;
                    break;
                }
            }

            if (found) {
                access_time[i] = time;
                fprintf(out, "-1\n");
            } else {
                if (i < block_num) {
                    cache_fully[i].tag = tag;
                    cache_fully[i].valid = true;
                    size = min(size + 1, block_num);
                    access_time[i] = time;
                    fprintf(out, "-1\n");
                } else {
                    // the cacheline is full
                    int tar = 0, tar_time = access_time[0];
                    for (int j = 0; j < block_num; j++) {
                        if (policy == FIFO) {
                            // find max one
                            if (tar_time < access_time[j]) {
                                tar = j;
                                tar_time = access_time[j];
                            }
                        } else if (policy == LRU) {
                            // find min one
                            if (tar_time > access_time[j]) {
                                tar = j;
                                tar_time = access_time[j];
                            }
                        } else if (policy == my_policy) {
                            // same as LRU
                            if (tar_time > access_time[j]) {
                                tar = j;
                                tar_time = access_time[j];
                            }
                        }
                    }
                    fprintf(out, "%d\n", cache_fully[tar].tag);

                    cache_fully[tar].tag = tag;
                    cache_fully[tar].valid = true;
                    access_time[tar] = time;
                }
            }

            time++;
        }
    }

    // clean up
    fclose(in);
    fclose(out);

    switch (asso) {
    case direct_map:
        free(cache_direct);
        break;
    case fully:
        free(cache_fully);
        free(access_time);
        break;
    case four_way:
        free(cache_four);
        free(set_size);
        free(set_acc_time);
        break;
    }

    return 0;
}
