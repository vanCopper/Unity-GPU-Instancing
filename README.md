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

##### 1.1 动态合批

1. 新建一个球体的Prefab用于测试

   ![](./images/prefab.png)

2. 新建**GPUInstancing**脚本，用于生成Sphere实例

   ```c#
   using System.Collections;
   using System.Collections.Generic;
   using UnityEngine;
   
   public class GPUInstancing : MonoBehaviour 
   {
   
       public Transform prefab;
   
       public int instances = 5000;
   
       public float radius = 50f;
   
       void Start()
       {
           for (int i = 0; i < instances; i++)
           {
               Transform t = Instantiate(prefab);
               t.localPosition = Random.insideUnitSphere * radius;
               t.SetParent(transform);
           }
       }
   }
   
   ```

3. 新建**GameObject**并添加脚本**GPUInstancing**，生成半径50，实例数5000。

   ![](./images/test-object.png)

4. 将相机位置设置在（0，0，-100）以保证所有物体均在视野范围内。关掉光源的**Shadow**，设置相机的渲染路径为**Forward Rendering**。

   ![](./images/sphere-of-spheres.png)

   可以看到总共有5002次DrawCall(Batches),其中5000次是场景中的球体的绘制。尽管开启了动态合批，但由于Sphere的模型过大，导致无法动态合批。而且FPS只有0.6

5. 将Sphere替换为Cube，观察合批结果

   ![](./images/sphere-of-cubes.png)

   可以看到这时只有8次DrawCall(Batches)，4994个Cube被动态合批了。FPS也从0.6fps上升到了75fps。

##### 1.2 GPU Instancing 测试

​	GPU Instancing 并不是默认开启的。Shader需要特殊处理才能支持GPU Instancing。Unity的standard shader中是有开启GPU Instancing选项的，如果是自定义Shader，就需要自己去处理。我们先来用Sphere的渲染来测试下，5000个Sphere不开启GUP Instancing的情况：

![](./images/sphere-no-instancing.png)

因Sphere无法动态合批，5000个Sphere就5000次DrawCall。

现在把材质中的**Enable GPU Instancing**选项开启：

![](./images/enable-instancing.png)

再次运行程序：

![](./images/sphere-instancing.png)

5000个Sphere被合批至10个DrawCall中处理了。被Instancing的Draw Call都被标记为了**Draw Mesh(instanced)**了。

##### 1.3 什么是GPU Instancing

GPU Instancing是指由GPU和图形API支持的，用一个DrawCall同时绘制多个具有相同网格物体的技术。假如现在有一个包含大量模型的场景，而这些模型的网格数据都一样，不同的仅仅是世界空间下坐标不同。如果按照正常的渲染流程，DrawCall次数是和物件数量相同的，随着物件数量的上升CPU往GPU上传的数据就会越来越多，很快就会遇到性能的瓶颈。

使用GPU Instancing技术时，数据的上传是一次性打包上传至GPU的，紧接着调用GPU和图形的API利用这些数据绘制多个物件。Unity中的具体实现步骤如下：

* 将Per-Instance Data(世界矩阵，颜色等自定义变量)打包成Uniform Array，存储在Instance Constant Buffers中
* 对于可以使用Instancing的Batch，调用各平台图形API的Instancing DrawCall，为每个Instance生成一个不同的SV_InstanceID
* 在Shader中使用SV_InstanceID作为Uniform Array的索引来获取当前Instance的Per-Instance Data

GPU Instancing技术并不是总能提高性能的，如果场景中有大量使用相同材质和相同网格的物体并性能问题是由DrawCall次数过多导致的，这时使用GPU Instancing可以得到不错的性能提升。在实际的游戏项目中植被和树木是最适合使用的。这里要注意的是GPU Instancing是通过减少DrawCall来降低CPU开销的，但这同事也会为GPU带来额外的开销。**适合的才是最好的，切勿沉迷性能优化无法自拔**。

目前GPU Instancing支持的平台：

* DirectX11 and DirectX12 on Windows
* OpenGL Core 4.1+/ES3.0+ on Windows, macOS, Linux, iOS and Android
* Metal on macOS and iOS
* Vulkan on Windows, Linux and Android
* PlayStation 4 and Xbox One
* WebGL(requires WebGL 2.0 API)

使用GPU Instancing 技术注意事项：

* 使用Lightmap的物体无法使用Instancing
* 受不同Light Probe / Reflection Probe影响的物体无法使用Instancing
* 使用包含多个Pass的Shader物体，只有第一个Pass可以Instancing
* 前向渲染时，受多个光源影响的物体只有Base Pass可以Instancing, Add Passes不行
* Instancing 适用于MeshRenderer组件和Graphics.DrawMesh()
* 需要物件使用相同的Material和Mesh
* 需要把Shader改成Instanced的版本
* 当所有条件均满足的情况下，Instancing是自动进行的，并且优先级高于 Static/Dynamic Batching



> http://gad.qq.com/article/detail/28456
>
> https://catlikecoding.com/unity/tutorials/rendering/part-19/
>
> https://learnopengl.com/Advanced-OpenGL/Instancing

