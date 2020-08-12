# SHIT-Backend

## bpd_origin分支

- 该分支无TLB，分支预测为简单的GShare分支预测，无RAS，解决了部分关键路径，频率为88MHz，性能得分48

- 通过所有的功能测试、性能测试

- 其中快速排序、冒泡排序和Coremark得分较低

## 总体概述

- 任务：需要添加推测唤醒和旁路
- 修改：LSU到ALU的旁路，ALU到LSU的旁路（到LSU的第一阶段，第二阶段由于是访问存储器，访问的地址已经计算出来了，所以不能旁路到第二阶段）
- LOAD指令的推测唤醒，Store指令的提前唤醒（已经完成），Store可以再提前一个周期唤醒，因为可以旁路到LSU第一阶段（TAG访问））
- LOAD唤醒失败的撤回：需要撤回流水线中位于Issue/RF, RF/EX阶段的指令，其方法是Flush流水线，并且将Scoreboard恢复到2周期（或者n周期之前的）；也就意味着，在每一次发射Load的时候，都需要对Scoreboard做一次的Snapshot，这个Snapshot是FIFO结构，如果唤醒成功就会被覆盖

