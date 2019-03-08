# Unity GPU Instancing
运行环境：Unity 2018.3.2f1



Unity 提供了**Static Batching**和**Dynamic Batching**两种方式来减少DrawCall。**Static Batching**会将多个使用相同材质的Mesh合并成一个，以此来减少DrawCall，这种方式会产生更多的Mesh数据。



> http://gad.qq.com/article/detail/28456
>
> https://catlikecoding.com/unity/tutorials/rendering/part-19/
>
> https://mp.weixin.qq.com/s?__biz=MzU5OTAwMjM4Ng==&mid=2247483762&idx=1&sn=b85b232621c50ddf6c57c0d263eea73d&chksm=febadd0fc9cd54198277b68dae8d7ed6c6aa323acaa74c39723a962643ac147977d99754ba66&mpshare=1&scene=1&srcid=0308uqzh07quQOZMoAJ6YEFu#rd

