//
//  ViewController.swift
//  FirstMetal
//
//  Created by 山下希流 on 2019/09/07.
//  Copyright © 2019年 KiryuYamashita. All rights reserved.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {
    
    private let device = MTLCreateSystemDefaultDevice()!
    
    private let positionData: [Float] =
    [
        -1, -1, 0, +1,
        -1, +1, 0, +1,
        +1, -1, 0, +1,
        +1, +1, 0, +1,
    ];
    
    private var time: Float!;
    private var frameTime: Float!
    
    private var bufferResolution : MTLBuffer! = nil
    private var bufferTimer : MTLBuffer! = nil
    
    private var commandQueue: MTLCommandQueue!
    private var renderPassDescriptor: MTLRenderPassDescriptor!
    private var bufferPosition: MTLBuffer!
    private var bufferColor: MTLBuffer!
    private var renderPipelineState: MTLRenderPipelineState!
    private var metalLayer: CAMetalLayer!;
    
    var timer = Timer()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 720, height: 720));
        view.layer = CALayer();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // ビューを初期化
        initLayer();
        
        // 時間初期化
        initTime();
        
        // Metalのセットアップ
        setupMetal()
        // バッファーを作成
        makeBuffers()
        // パイプラインを作成
        makePipeline()
        //timer処理
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
            self.draw()
        })
    }

    
    
    private func initLayer(){
        // レイヤーを作成
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer!.frame
        view.layer!.addSublayer(metalLayer)
    }
    
    private func setupMetal() {
        // MTLCommandQueueを初期化
        commandQueue = device.makeCommandQueue()
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        // このRender Passが実行されるときの挙動を設定
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        // 背景色は黒にする
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    }
    
    private func makeBuffers() {
        let size = positionData.count * MemoryLayout<Float>.size
        // 位置情報のバッファーを作成
        bufferPosition = device.makeBuffer(bytes: positionData, length: size)
        bufferResolution = device.makeBuffer(length: 2*MemoryLayout<Float>.size, options: [])
        bufferTimer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    }
    
    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "myVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "myFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        // レンダーパイプラインステートを作成
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func draw() {
        // ドローアブルを取得
        guard let drawable = metalLayer.nextDrawable() else {fatalError()}
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        // コマンドバッファを作成
        guard let cBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        
        time += frameTime;
        
        updateResolution(width: Float(720), height: Float(720))
        updateTime(time: Float(time));
        
        // エンコーダ生成
        let encoder = cBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        )!
        
        encoder.setRenderPipelineState(renderPipelineState)
        // バッファーをフラグメントシェーダーに送る
        encoder.setFragmentBuffer(bufferResolution, offset: 0, index: 0)
        encoder.setFragmentBuffer(bufferTimer, offset: 0, index: 1)
        // バッファーをバーテックスシェーダーに送る
        encoder.setVertexBuffer(bufferPosition, offset: 0, index: 0)
        // 四角形を作成
        encoder.drawPrimitives(type: MTLPrimitiveType.triangleStrip,
                               vertexStart: 0,
                               vertexCount: 4)
        // エンコード完了
        encoder.endEncoding()
        // 表示するドローアブルを登録
        cBuffer.present(drawable)
        // コマンドバッファをコミット（エンキュー）
        cBuffer.commit()
    }
    
    private func updateResolution(width: Float, height: Float){
        memcpy(bufferResolution.contents(), [width, height], MemoryLayout<Float>.size * 2)
    }
    
    private func updateTime(time: Float) {
        let pointer = bufferTimer.contents();
        let value = pointer.bindMemory(to: Float.self, capacity: 1);
        value[0] = time;
    }
    
    private func initTime(){
        time = 0.0;
        frameTime = 1.0/60.0;
    }
    
}

