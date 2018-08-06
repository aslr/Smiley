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
    public let device: MTLDevice
    var view:MTKView
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLComputePipelineState!
   
    init?(metalKitView: MTKView)
    {
        self.device = metalKitView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.view = metalKitView
        super.init()
        self.pipelineState = createPipeline()
    }
    
    func createPipeline() -> MTLComputePipelineState?
    {
        let library = device.makeDefaultLibrary()!
        
        do {
            if let kernel = library.makeFunction(name: "compute")
            {
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

    func draw(in view: MTKView)
    {
        if let drawable = view.currentDrawable
        {
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            let threadGroupCount = MTLSizeMake(2, 2, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        // let aspect = Float(size.width) / Float(size.height)
    }
}

