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
    // time
    let timeStep = Float(1.0/60.0)
    var time = Float(0)
    
    // mouse
    var mouse = NSPoint(x: 0, y: 0)
    
    public let device: MTLDevice
    
    // private ivars
    private var view:MTKView
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLComputePipelineState!
    private var inputBuffer: MTLBuffer!
    
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
                self.inputBuffer = device.makeBuffer(length: MemoryLayout<float4>.size, options: [])
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
            let inputBufferPtr = inputBuffer.contents().bindMemory(to: float4.self, capacity: 1)
            inputBufferPtr.pointee = float4(Float(mouse.x),Float(mouse.y),0.0,time)
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
            let threadGroupCount = MTLSizeMake(2, 2, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
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

