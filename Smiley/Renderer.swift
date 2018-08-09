//
//  Renderer.swift
//  Smiley
//
//  Created by João Varela on 05/08/2018.
//  Copyright © 2018 João Varela. All rights reserved.
//

// Our platform independent renderer class

import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate
{
    let timeStep = Float(1.0/60.0)
    var time = Float(0)
    
    public let device: MTLDevice
    private var view:MTKView
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLComputePipelineState!
    private var timeBuffer: MTLBuffer!
    
    // ---------------------------------------------------------------------------------
    // init
    // ---------------------------------------------------------------------------------
    init?(metalKitView: MTKView)
    {
        self.device = metalKitView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.view = metalKitView
        super.init()
        self.pipelineState = createPipeline()
    }
    
    // ---------------------------------------------------------------------------------
    // createPipeline
    // ---------------------------------------------------------------------------------
    func createPipeline() -> MTLComputePipelineState?
    {
        let library = device.makeDefaultLibrary()!
        
        do {
            if let kernel = library.makeFunction(name: "compute")
            {
                self.timeBuffer = device.makeBuffer(length: MemoryLayout<float4>.size, options: [])
                return try device.makeComputePipelineState(function: kernel)
            }
            else
            {
                view.printView("Setting pipeline state failed")
            }
        }
        
        catch let error {
             view.printView("\(error)")
        }
        
        return nil
    }
    
    // ---------------------------------------------------------------------------------
    // draw
    // ---------------------------------------------------------------------------------
    func draw(in view: MTKView)
    {
        if let drawable = view.currentDrawable
        {
            time += timeStep
            let timeBufferPtr = timeBuffer.contents().bindMemory(to: float4.self, capacity: 1)
            timeBufferPtr.pointee = float4(0.0,0.0,0.0,time)
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(timeBuffer, offset: 0, index: 0)
            let w = pipelineState.threadExecutionWidth
            let h = pipelineState.maxTotalThreadsPerThreadgroup / w;
            let threadGroupCount = MTLSize(width: w, height: h, depth: 1)
            let threadGroups = MTLSize(width: (drawable.texture.width + w - 1) / w,
                                       height: (drawable.texture.height + h - 1) / h,
                                       depth: 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        // let aspect = Float(size.width) / Float(size.height)
    }
}

