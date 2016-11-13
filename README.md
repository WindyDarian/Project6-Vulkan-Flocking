Vulkan Flocking: compute and shading in one pipeline!
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 6**

* Ruoyu Fan
* Tested on: Windows 10 x64, i7-4720HQ @ 2.60GHz, 16GB Memory, GTX 970M 3072MB (personal laptop)
  * Visual Studio 2015 & LunarG Vulkan SDK 1.0.30.0

![](screenshots/1.gif)

### Q&A

> * Why do you think Vulkan expects explicit descriptors for things like
generating pipelines and commands? HINT: this may relate to something in the
comments about some components using pre-allocated GPU memory.

Because command buffers in Vulkan lives in pre-allocated GPU command pool, and we cannot
update them once created, they need updatable descriptor sets to figure out which
buffers to operate on and how to correctly map data from buffers to inputs and outputs of every stages of the pipeline.
This way we can use a single command buffer to operate on varying data.

> * Describe a situation besides flip-flop buffers in which you may need multiple
descriptor sets to fit one descriptor layout.

For example, in deferred shading pipeline's debug view, instead of passing current state and all g-buffers into debug fragment shader, I can use depth/color/normal maps as different descriptor sets in one descriptor layout, and use different sets according to current configration

> * What are some problems to keep in mind when using multiple Vulkan queues?
>   * take into consideration that different queues may be backed by different hardware
>   * take into consideration that the same buffer may be used across multiple queues>

* Queue operations on different queues have no implicit ordering constraints, and may execute in any order. Explicit ordering constraints between queues can be expressed with semaphores and fences. (https://www.khronos.org/registry/vulkan/specs/1.0/xhtml/vkspec.html#fundamentals-queueoperation)
* When two queues are operating on the same buffer, we need to take race condition into consideration.

> * What is one advantage of using compute commands that can share data with a
rendering pipeline?

Don't need to copy the inputs and outputs of compute and render stages around, that might be some giant amount of data for copying.

### Credits

* [Vulkan examples and demos](https://github.com/SaschaWillems/Vulkan) by [@SaschaWillems](https://github.com/SaschaWillems)
