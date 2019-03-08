# Unity GPU Instancing
运行环境：Unity 2018.3.2f1



Unity 提供了**Static Batching**和**Dynamic Batching**两种方式来优化渲染性能。

* **Static Batching**

  **Static Batching**会在Build阶段提取多个使用相同材质的，且不会移动，旋转和缩放模型的**Vertex buffer**和**Index buffer**。然后将顶点数据变换到世界空间下，存储到最终**Static Batching**所使用的**Vertex buffer**中，并记录每个子模型的**Index buffer**在**Static Batching**所使用的**Index buffer**中的位置。在绘制阶段，会一次性提交合并后的模型顶点数据，最终引擎会根据子模型的可见性确定需要绘制的子模型，设置一次渲染状态，再调用多次**Draw Call**分别绘制子模型。

  所以**Static Batching**并没有减少**Draw Call**的数量，但在绘制阶段避免了多次数据提交和渲染状态的切换。

* **Dynamic Batching**

  **Dynamic Batching**会在运行时将使用同一材质的模型进行合并渲染，也就是将符合条件的GameObject放在一个**Draw Call**中绘制。使用**Dynamic Batching**有一些限制：

  1. 模型最高900个顶点属性，300个顶点。假如我们的Shader中每个顶点使用了Position, Normal, UV,那么模型只能有300个顶点。如果在Shader中使用了Position, Normal, UV0, UV1, Tangent,那么顶点数就要减少到180个（5*180=900）。
  2. GameObject之间有镜像变换的不能进行合批
  3. 使用Multi-pass Shader的GameObject禁止合批
  4. 拥有lightmap的对象，无法合批
  5. GameObject接收实时阴影无法合批

  **Dynamic Batching**在降低Draw Call的同时会导致额外的CPU性能消耗，所以仅在合批操作的性能消耗小于不合批，**Dynamic Batching**才有意义。

> http://gad.qq.com/article/detail/28456
>
> https://catlikecoding.com/unity/tutorials/rendering/part-19/
>
> https://mp.weixin.qq.com/s?__biz=MzU5OTAwMjM4Ng==&mid=2247483762&idx=1&sn=b85b232621c50ddf6c57c0d263eea73d&chksm=febadd0fc9cd54198277b68dae8d7ed6c6aa323acaa74c39723a962643ac147977d99754ba66&mpshare=1&scene=1&srcid=0308uqzh07quQOZMoAJ6YEFu#rd

