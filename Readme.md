# Superscalar-HIT-Core

**S**uperscalar **HIT** **Core**（简称SHIT Core） 是一个基于MIPS指令集的乱序四发射处理器。在`xc7a200tfbg676-2`平台上运行频率88MHz。

Superscalar HIT Core is a quad-issue out-of-order processor core implementing MIPS ISA. It runs at the frequency of 88MHz on Xilinx `xc7a200tfbg676-2` FPGA. 

为哈尔滨工业大学（深圳）1队2020年“龙芯杯”竞赛参赛作品。

## 特性

- 10级动态调度超标量流水线
- 4KiB I-Cache
- 16KiB 非阻塞 D-Cache
- 取指宽度2，执行宽度4，提交宽度2
- 算术指令与乘除法指令全乱序执行，Load/Store指令半乱序执行
- 基于PRF的寄存器重命名
- 实现部分CP0寄存器和特权指令
- GShare分支预测器

具体特性详见设计文档。

恳请批评指正，我们期待宝贵的意见和建议。

## Specifications

- 10-stage dynamic scheduled superscalar pipeline
- 4 KiB I-Cache
- 16 KiB Non-Blocking D-Cache
- 2-wide instruction fetch, 4-wide issue, 2-wide commit
- Full out-of-order execution of arithmetic instructions, half out-of-order execution of Load/Store(Load can't bypass the Store before it in program order)
- Explicit register renaming based on PRF
- Support privileged CP0 instructions 
- GShare branch predictor

Design document and slides is available only in Chinese.


## 作者 Authors

- 胡博涵 Bohan Hu (hubohancser@gmail.com)
- 黎庚祉 Gnegzhi Li (willsonlgz@gmail.com)
- 施杨 Yang Shi (Gyhanis@gmail.com)
- 王世焜 Shikun Wang (tanimodoli@gmail.com)
