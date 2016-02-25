---
layout: post
title: Generating combinations for N-dimensional searches
date: '2014-01-27 15:38:00'
---

Problems involving searches are very common in computer science, and they are often N-dimensional, meaning you are looking for a *combination* of values that yields some outcome. For example, you might be looking for all pairs of numbers whose sum is 50. This is trivial to express in most modern programming languages, and would usually be done with a nested for loop like this:

```c
for (int a = 0; a < 50; a++)
  for (int b = 0; b < 50; b++)
    if (a+b == 50) printf("%d + %d == 50\n", a, b);
```

Say that you now wanted to find all triples of numbers that sum to 50. You might be tempted to add another nested for loop as such:

```c
for (int a = 0; a < 50; a++)
  for (int b = 0; b < 50; b++)
    for (int c = 0; c < 50; c++)
      if (a+b+c == 50) printf("%d + %d + %d == 50\n", a, b, c);
```

While this is still legible, it should become apparent that this won't scale very well as you add more dimensions. More importantly though, this approach also requires you to know in advance the number of numbers you want to add. If you were to build a program that let the user specify how many numbers she wanted to use, this simply wouldn't work.

I had exactly this problem, and came up with a pretty neat solution. It has probably been done before elsewhere, but I figured I'd document it for future reference.

The following code lets you find all combinations of N variables with values between 0 and S. By multiplying the value with a fraction, you can also extend this to non-integral numbers.

```c
int x, n, i;
int vars[N];
double ns = pow(S, N);

for (n = 0; n < ns; n++) {
  x = n;
  for (i = 0; i < N; i++) {
    vars[i] = x % S;
    x /= S;
  }
  /*
   * vars[0..S] now holds one of the
   * combinations of values for the
   * N variables
   */
}
```

We can use this to implement the example I gave above of letting the user specify the number of numbers to sum:

```c
int N = /* get user's number */
int S = 50;
int x, n, i;
int *vars = calloc(N, sizeof(int));
double ns = pow(S, N);

for (n = 0; n < ns; n++) {
  int sum = 0;

  x = n;
  for (i = 0; i < N; i++) {
    vars[i] = x % S;
    x /= S;

    sum += vars[i];
  }

  if (sum == 50) {
    for (i = 0; i < N; i++) {
      if (i == 0)
        printf("%d", vars[i]);
      else
        printf(" + %d", vars[i]);
    }
    printf(" = 50\n");
  }
}

free(vars);
```

While it is certainly longer, it is also much more flexible. If the values of N and S are known at compile-time, we can also let the compiler unroll the loops completely for us to avoid the runtime termination checks!