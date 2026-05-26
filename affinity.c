#define _GNU_SOURCE

#include <stdio.h>
#include <sched.h>
#include <unistd.h>

int main() {

    int cpu = sched_getcpu();

    printf("Process running on CPU: %d\n", cpu);

    sleep(20);

    return 0;
}
