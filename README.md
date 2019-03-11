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

##### 1.1 Many Spheres

1. 新建一个球体的Prefab用于测试

   ![](./images/prefab.png)

2. 新建**GPUInstancingTest**脚本，用于生成Sphere实例

   ```c#
   using UnityEngine;
   public class GPUInstancingTest : MonoBehaviour {
   
   	public Transform prefab;
   
   	public int instances = 5000;
   
   	public float radius = 50f;
   
   	void Start () {
   		for (int i = 0; i < instances; i++) {
   			Transform t = Instantiate(prefab);
   			t.localPosition = Random.insideUnitSphere * radius;
   			t.SetParent(transform);
   		}
   	}
   }
   ```

3. 新建**GameObject**并添加脚本**GPUInstancingTest**，生成半径50，实例数5000。

   ![](./images/test-object.png)

4. 将相机位置设置在（0，0，-100）以保证所有物体均在视野范围内。关掉光源的Shadow，设置相机的渲染路径为**Forward Rendering**。

   ![](./images/sphere-of-spheres.png)

   可以看到总共有5002次DrawCall(Batches),其中5000次是场景中的球体的绘制。尽管开启了动态合批，但由于Sphere的模型过大，导致无法动态合批。

5. 将Sphere替换为Cube，观察合批结果

   ![](./images/sphere-of-cubes.png)

   可以看到这时只有8次DrawCall，4994个Cube被动态合批了。Graphics FPS也从35fps上升到了83fps。这里的FPS是指渲染帧而不是真实游戏帧率。

> http://gad.qq.com/article/detail/28456
>
> https://catlikecoding.com/unity/tutorials/rendering/part-19/
>
> https://mp.weixin.qq.com/s?__biz=MzU5OTAwMjM4Ng==&mid=2247483762&idx=1&sn=b85b232621c50ddf6c57c0d263eea73d&chksm=febadd0fc9cd54198277b68dae8d7ed6c6aa323acaa74c39723a962643ac147977d99754ba66&mpshare=1&scene=1&srcid=0308uqzh07quQOZMoAJ6YEFu#rd

