🐢 gobench is a simple bash script that does its best to automate and visualize differential benchmarking for Go projects.

### prepare it ...

make sure you have `git`, `go` and [benchcmp](go get golang.org/x/tools/cmd/benchcmp).

### install it ...

just put the `gobench.sh` file in `/usr/local/bin` or whatever it's in your `$PATH` and make it executable:

```shell
curl -s https://raw.githubusercontent.com/evilsocket/gobench/master/gobench.sh -O /usr/local/bin/gobench
chmod +x /usr/local/bin/gobench
```

### run it ...

just `cd` into a git repository with local changes you want to benchmark against the `master` branch and run `gobench`. If you only want to 
run specific benchmarks instead of the entire suite, you can use the first parameter as the `-bench` filter, for instance `gobench Something` will only run benchmarks with the string `Something` in their declaration.

