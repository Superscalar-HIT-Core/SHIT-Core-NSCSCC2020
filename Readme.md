# Superscalar-HIT-Core

**S**uperscalar **HIT** **Core**（简称SHIT Core） 是一个基于MIPS指令集的乱序四发射处理器。在`xc7a200tfbg676-2`平台上运行频率88MHz。

为哈尔滨工业大学（深圳）1队2020年“龙芯杯”竞赛参赛作品。

## 特性

- 10级动态调度超标量流水线
- 4KiB I-Cache
- 16KiB 非阻塞 D-Cache
- 取指宽度2，执行宽度4，提交宽度2
- 算术指令与乘除法指令全乱序执行，Load/Store指令半乱序执行
- 基于PRF的寄存器重命名
- 实现部分CP0寄存器和特权指令

具体特性详见设计文档。

恳请批评指正，我们期待宝贵的意见和建议。

## 作者

- 胡博涵(hubohancser@gmail.com)
- 黎庚祉(willsonlgz@gmail.com)
- 施杨(Gyhanis@gmail.com)
- 王世焜(tanimodoli@gmail.com)
