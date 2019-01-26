//
//  GameScene.swift
//  DinoRun
//
//  Created by rain on 2019/1/25.
//  Copyright © 2019年 rain. All rights reserved.
//

import SpriteKit
import GameplayKit

let dinoCategory: UInt32 = 1 << 0
let worldCategory: UInt32 = 1 << 1
let treeCategory: UInt32 =  1 << 2

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    enum GameStatus {
        case idle
        case running
        case over
    }
    
    var gameStatus: GameStatus = .idle
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var dino: SKSpriteNode!
    var dinoSpeed: CGFloat = 0.02
    
    var treeTexture: SKTexture!
    var trees:SKNode!
    
    var groundPosition:CGPoint!
    
    override func didMove(to view: SKView) {
        //backgroundColor
        self.backgroundColor =  SKColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        //physicsWorld
        self.physicsBody  = SKPhysicsBody(edgeLoopFrom: self.frame)
        //gravity
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
        self.physicsWorld.contactDelegate = self
        
        //dino
        dino = SKSpriteNode(imageNamed: "dino-01")
//        dino.setScale(1.5)
        dino.position = CGPoint(x: self.frame.size.width * 0.35 ,y:self.frame.size.height * 0.6)
        self.dinoStartRun()
        addChild(dino)
        dino.physicsBody = SKPhysicsBody(circleOfRadius: dino.size.height / 2.0)
        dino.physicsBody?.allowsRotation = false
        dino.physicsBody?.categoryBitMask = dinoCategory
        dino.physicsBody?.contactTestBitMask = worldCategory
        
        groundPosition = CGPoint(x: 0, y: self.frame.size.height/2)
        //floor
        let groundTexture = SKTexture(imageNamed: "floor")
        groundTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (groundTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
//            sprite.setScale(0.8)
            // SKSpriteNode的默认锚点为(0.5,0.5)即它的中心点。
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundPosition.y);
            self.moveGround(sprite: sprite, timer: 0.02)
            self.addChild(sprite)
        }
        let ground = SKNode()
        ground.position = groundPosition
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 1))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        //sky
        
        self.startCreateRandomTrees()
    }
    
    //陆地及天空移动动画
    func moveGround(sprite:SKSpriteNode,timer:CGFloat) {
        let moveGroupSprite = SKAction.moveBy(x: -sprite.size.width, y: 0, duration: TimeInterval(timer * sprite.size.width))
        let resetGroupSprite = SKAction.moveBy(x: sprite.size.width, y: 0, duration: 0.0)
        //永远移动 组动作
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroupSprite,resetGroupSprite]))
        sprite.run(moveGroundSpritesForever)
    }
    
    ///  恐龙跑的动画
    func dinoStartRun()  {
        let dinoTexture1 = SKTexture(imageNamed: "dino-01")
        dinoTexture1.filteringMode = .nearest
        let dinoTexture2 = SKTexture(imageNamed: "dino-02")
        dinoTexture2.filteringMode = .nearest
        let anim = SKAction.animate(with: [dinoTexture1,dinoTexture2], timePerFrame: 0.2)
        dino.run(SKAction.repeatForever(anim), withKey: "run")
    }
    ///  恐龙停止跑动动画
    func dinoStopRun()  {
        dino.removeAction(forKey: "run")
    }
    
    func createTrees(){
        let randomNum = arc4random_uniform(UInt32(2));
        switch randomNum {
        case 0:
            self.treeTexture =  SKTexture(imageNamed: "tree-1")
            break;
        case 1:
            self.treeTexture =  SKTexture(imageNamed: "tree-2")
            break;
        default:
            self.treeTexture =  SKTexture(imageNamed: "tree-1")
            break;
        }
        let tree = SKSpriteNode(texture: self.treeTexture)
        tree.anchorPoint = CGPoint(x: 0, y: 0)
        tree.position = CGPoint(x: self.frame.size.width+treeTexture.size().width, y: groundPosition.y)
        tree.physicsBody = SKPhysicsBody(rectangleOf: tree.size)
        tree.physicsBody?.isDynamic = false
        tree.physicsBody?.categoryBitMask = treeCategory
        tree.physicsBody?.contactTestBitMask = dinoCategory
        let distanceToMove = CGFloat(self.frame.size.width + 2.0*self.treeTexture.size().width)
        let moveTrees = SKAction.moveBy(x: -distanceToMove, y: 0, duration: TimeInterval(0.01 * distanceToMove))
        let removeTrees = SKAction.removeFromParent()
        let moveTreesAndRemove = SKAction.sequence([moveTrees,removeTrees])
        tree.run(moveTreesAndRemove)
        
        addChild(tree)
    }
    
    func startCreateRandomTrees(){
        let spawn = SKAction.run {
            self.createTrees()
        }
//        let randoomNum = arc4random_uniform(UInt32(5))
        let delay = SKAction.wait(forDuration: 3.5, withRange: 2.0)
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever, withKey: "createTree")
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            runningStatus()
            break
        case .running:
            for _ in touches {
                dino.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                // 施加一个均匀作用于物理体的推力
                dino.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
            }
            break
        case .over:
            idleStatus()
            break
        }
    }
    
    func idleStatus() {
        gameStatus = .idle
    }
    
    func runningStatus() {
        gameStatus = .running
    }
    
    func overStatus() {
        gameStatus = .over
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
