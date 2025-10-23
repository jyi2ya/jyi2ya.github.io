Tue Sep 23 16:02:23 CST 2025

`git@github.com:IntegralPilot/rustc_codegen_jvm.git`

试吃一下

编译了半天发现编不出来，一看原来是要 gradle 8.5 以上，我还在用 4.4.1

编译出来了，但是运行 hello world 失败了，怀疑是不能用 println 导致的

跑通了！跑了个空的程序出来嘻嘻

接下来研究一下怎么做 io

Tue Oct 14 15:20:02 CST 2025

离的太久了，忘记自己之前是怎么操作的了。重新研究一下。

#figure(
  ```toml
  # Throwing a JVM exception will unwind and give a stack trace, no need for rust to handle unwinding.
  [profile.debug]
  panic = "abort"

  [profile.release]
  panic = "abort"
  rustflags = [
    "-C", "link-args=--release"
  ]

  [build]
  # target = '/home/jyi/.cargo/codegen/jvm-unknown-unknown.json'
  rustflags = [
    "-Z", "codegen-backend=/home/jyi/.cargo/codegen/jvm/librustc_codegen_jvm.so",
    "-C", "linker=/home/jyi/.cargo/codegen/jvm/java-linker",
    "-C", "link-args=/home/jyi/src/lang/rustc_codegen_jvm/library/build/distributions/library-0.1.0/lib/library-0.1.0.jar /home/jyi/src/lang/rustc_codegen_jvm/library/build/distributions/library-0.1.0/lib/kotlin-stdlib-2.1.20.jar /home/jyi/src/lang/rustc_codegen_jvm/library/build/distributions/library-0.1.0/lib/annotations-13.0.jar --r8-jar /home/jyi/src/lang/rustc_codegen_jvm/vendor/r8.jar --proguard-config /home/jyi/src/lang/rustc_codegen_jvm/proguard/default.pro"
  ]
  target-dir = './target'

  # [unstable]
  # build-std = ['compiler_builtins']
  ```
)

这个是之前写的配置文件。

哦，因为之前 rust 编译器升级过了，所以编译出来的 jvm toolchain 不能用了。得重新编译。坏

进 `rustc_codegen_jvm` 仓库 `cargo build` 一下……失败了，哈哈，不知道发生了什么。

看看它的文档好了。原来要 `make all`。

#figure(
  ```plain
  error[E0046]: not all trait items implemented, missing: `name`
    --> src/lib.rs:52:1
    |
  52 | impl CodegenBackend for MyBackend {
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ missing `name` in implementation
    |
    = help: implement the missing item: `fn name(&self) -> &'static str { todo!() }`

  error[E0023]: this pattern has 3 fields, but the corresponding tuple variant has 2 fields
    --> src/lower1/types.rs:181:43
      |
  181 |         rustc_middle::ty::TyKind::Dynamic(a, _, _) => {
      |                                           ^  ^  ^ expected 2 fields, found 3
      |
    ::: /home/jyi/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/rustc-src/rust/compiler/rustc_type_ir/src/ty_kind.rs:154:13
      |
  154 |     Dynamic(I::BoundExistentialPredicates, I::Region),
      |             -----------------------------  --------- tuple variant has 2 fields
  ```
)

神秘报错。手动改一下 `src/lower1/types.rs`。

好了。顺便编译 codegen 的时候疑似不能开 `build-std`

```plain
[130] jyi-00-rust-dev 15:59 (master) ~/dev/jvm-hello
0 cat src/main.rs
pub fn ciallo(a: i32) -> i32 {
    a + 3
}

fn main() {}
jyi-00-rust-dev 16:00 (master) ~/dev/jvm-hello
0 cat Test.java
public class Test {
    public static void main(String[] args) {
        int result = jvm_hello.ciallo(114);
        System.out.println(result);
    }
}
jyi-00-rust-dev 16:00 (master) ~/dev/jvm-hello
0 java -cp target/release/deps/jvm_hello-44f2059582347d7a.jar Test.java
117
jyi-00-rust-dev 16:00 (master) ~/dev/jvm-hello
0
```

跑通了。

emmm，现在知道 int 和 static str 是可以用的。String 因为没有 std 不能用。

复杂的数据结构可以定义，但是似乎没法在 java 两边传递。很坏。

哦，Rust 的可以传出来，但是 java 的传不进去。

好像还是比较阴间……能写，但是不完全能写。还需要等一会。
