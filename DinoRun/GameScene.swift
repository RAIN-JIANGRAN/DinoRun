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
let floorCategory: UInt32 = 1 << 1
let trapCategory: UInt32 =  1 << 2

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    enum GameStatus {
        case idle
        case running
        case over
    }
    
    enum DinoStatus {
        case running
        case jumping
        case bending
    }
    
    var movingObjects: SKNode!
    
    var gameStatus: GameStatus = .idle
    var dinoStatus: DinoStatus = .running
    
    lazy var scoreLabelNode:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.zPosition = 100
        label.text = "0"
        return label
    }()
    
    var meters = 0 {
        didSet  {
            scoreLabelNode.text = "meters:\(meters)"
        }
    }
    
    private var spinnyNode : SKShapeNode?
    
    var dino: SKSpriteNode!
    var moveSpeed: CGFloat = 100

    let originSpeed:CGFloat = 1.5
    
    var treeTexture: SKTexture!
    var traps:SKNode!
    
    var groundPosition:CGPoint!
    
    override func didMove(to view: SKView) {
        //backgroundColor
        self.backgroundColor =  SKColor(red: 1, green: 1, blue:1, alpha: 0)
        //physicsWorld
        self.physicsBody  = SKPhysicsBody(edgeLoopFrom: self.frame)
        //gravity
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -8.0)
        
        self.physicsWorld.contactDelegate = self
        
        movingObjects = SKNode()
        self.addChild(movingObjects)
        traps = SKNode()
        movingObjects.addChild(traps)
        
        //dino
        dino = SKSpriteNode(imageNamed: "dino-01")
//        dino.setScale(1.5)
        dino.position = CGPoint(x: self.frame.size.width * 0.20 ,y:self.frame.size.height * 0.8)
//        dino.anchorPoint = CGPoint(x:0,y:0)
        self.dinoStartRun()
        addChild(dino)
        setDinoPhysicsBody()
        groundPosition = CGPoint(x: self.size.width/2, y: self.frame.size.height/2)
        //floor
        let groundTexture = SKTexture(imageNamed: "floor")
        groundTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (groundTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
//            sprite.setScale(0.8)
            // SKSpriteNode的默认锚点为(0.5,0.5)即它的中心点。
//            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundPosition.y);
            self.moveGround(sprite: sprite)
            movingObjects.addChild(sprite)
        }
        let ground = SKNode()
        ground.position = CGPoint(x: groundPosition.x, y: groundPosition.y );
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 0.1))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = floorCategory
        ground.physicsBody?.restitution = 0
        movingObjects.addChild(ground)
        //sky
        
        //label
        scoreLabelNode.fontColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        scoreLabelNode.zPosition = 100
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 3 * self.frame.size.height / 4)
        self.addChild(scoreLabelNode)
        
        idleStatus()
    }

    //陆地及天空移动动画
    func moveGround(sprite:SKSpriteNode) {
        let moveGroupSprite = SKAction.moveBy(x: -sprite.size.width, y: 0, duration: TimeInterval(sprite.size.width / moveSpeed))
        let resetGroupSprite = SKAction.moveBy(x: sprite.size.width, y: 0, duration: 0.0)
        //永远移动 组动作
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroupSprite,resetGroupSprite]))
        sprite.run(moveGroundSpritesForever,withKey:"sceneMoving")
    }
    
    ///  恐龙跑的动画
    func dinoStartRun()  {
        dinoStopBending()
        let dinoTexture1 = SKTexture(imageNamed: "dino-01")
        dinoTexture1.filteringMode = .nearest
        let dinoTexture2 = SKTexture(imageNamed: "dino-02")
        dinoTexture2.filteringMode = .nearest
        let anim = SKAction.animate(with: [dinoTexture1,dinoTexture2], timePerFrame: 0.2)
        dino.size = dinoTexture1.size()
        setDinoPhysicsBody()
        dino.run(SKAction.repeatForever(anim), withKey: "run")
        running()
    }
    
    func dinoBending(){
        dinoStopRun()
        let dinoTexture1 = SKTexture(imageNamed: "dino-03")
        dinoTexture1.filteringMode = .nearest
        let dinoTexture2 = SKTexture(imageNamed: "dino-04")
        dinoTexture2.filteringMode = .nearest
        let anim = SKAction.animate(with: [dinoTexture1,dinoTexture2], timePerFrame: 0.2)
        dino.size = dinoTexture1.size()
        setDinoPhysicsBody()
        dino.run(SKAction.repeatForever(anim),withKey:"bend")
        bending()
    }
    
    func setDinoPhysicsBody(){
        dino.physicsBody = SKPhysicsBody(circleOfRadius: dino.size.height/2)
        dino.physicsBody?.allowsRotation = false
        dino.physicsBody?.categoryBitMask = dinoCategory
        dino.physicsBody?.contactTestBitMask = floorCategory
        dino.physicsBody?.mass = 0.1
        dino.physicsBody?.restitution = 0
        
    }
    
    func dinoJumping(){
        dino.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        // 施加一个均匀作用于物理体的推力
        dino.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
        jumping()
    }
    ///  恐龙停止跑动动画
    func dinoStopRun()  {
        dino.removeAction(forKey: "run")
    }
    
    func dinoStopBending(){
        dino.removeAction(forKey: "bend")
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
//        tree.anchorPoint = CGPoint(x: 0, y: 0)
        tree.position = CGPoint(x: self.frame.size.width+treeTexture.size().width, y: groundPosition.y+tree.size.height/2)
        tree.physicsBody = SKPhysicsBody(texture: treeTexture, size: tree.size)
        tree.physicsBody?.isDynamic = false
        tree.physicsBody?.categoryBitMask = trapCategory
        tree.physicsBody?.contactTestBitMask = dinoCategory
        let distanceToMove = CGFloat(self.frame.size.width + 2.0*self.treeTexture.size().width)
        let moveTrees = SKAction.moveBy(x: -distanceToMove, y: 0, duration: TimeInterval(distanceToMove/moveSpeed))
        let removeTrees = SKAction.removeFromParent()
        let moveTreesAndRemove = SKAction.sequence([moveTrees,removeTrees])
        tree.run(moveTreesAndRemove)
        traps.addChild(tree)
    }
    
    func createPterosaur(){
        //获取恐龙蹲下时的高度
        let dinoBendingTexture = SKTexture(imageNamed: "dino-03")
        let bendingHeight = dinoBendingTexture.size().height
        let pterosaur = SKSpriteNode(imageNamed: "pterosaur-1")
        pterosaur.position = CGPoint(x:self.frame.size.width+pterosaur.size.width,
                                     y:10+groundPosition.y+bendingHeight+pterosaur.size.height/2)
        pterosaur.physicsBody = SKPhysicsBody(circleOfRadius: pterosaur.size.height/2)
        pterosaur.physicsBody?.isDynamic = false
        pterosaur.physicsBody?.categoryBitMask = trapCategory
        pterosaur.physicsBody?.contactTestBitMask = dinoCategory
        
        let distanceToMove = CGFloat(self.frame.size.width + 2.0*pterosaur.size.width)
        let movePterosaur = SKAction.moveBy(x: -distanceToMove, y: 0, duration: TimeInterval(distanceToMove/moveSpeed))
        let removePterosaur = SKAction.removeFromParent()
        let movePterosaurAndRemove = SKAction.sequence([movePterosaur,removePterosaur])
        
        //翼龙振翅动画
        let pterosaurTexture1 = SKTexture(imageNamed: "pterosaur-1")
        pterosaurTexture1.filteringMode = .nearest
        let pterosaurTexture2 = SKTexture(imageNamed: "pterosaur-2")
        pterosaurTexture2.filteringMode = .nearest
        let fly = SKAction.animate(with: [pterosaurTexture1,pterosaurTexture2], timePerFrame: 0.5)
        let flying = SKAction.repeatForever(fly)
        let anim = SKAction.group([flying,movePterosaurAndRemove])
        pterosaur.run(anim)
        traps.addChild(pterosaur)
    }
    
    func startCreateRandomTrees(){
        let spawn = SKAction.run {
            let randomNum = arc4random_uniform(UInt32(3));
            if(randomNum == 0){
                self.createPterosaur()
            }else{
                self.createTrees()
            }
           
        }
//        let randoomNum = arc4random_uniform(UInt32(5))
        let delay = SKAction.wait(forDuration: 3.5, withRange: 2.0)
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever, withKey: "createTree")
    }
    
    func stopCreateTrees(){
        self.removeAction(forKey: "createTree")
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            runningStatus()
            break
        case .running:
            
            switch dinoStatus {
            case .bending:
                dinoStartRun()
                break
            case .running:
                dinoJumping()
                break
            case .jumping:
//                dinoJumping()
                break
            default:
                break
            }
                
            break
        case .over:
            idleStatus()
            break
        }
        print(dinoStatus)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameStatus == GameStatus.running){
            for t in touches{
                let position = t.location(in: self)
                let prevPosition = t.previousLocation(in: self)
                if(prevPosition.y > position.y + 5){
                    if(dinoStatus == .running){
                        dinoBending()
                        
                    }
                  
                }
            }
        }
    }
    
    func running(){
        dinoStatus = .running
    }
    
    func jumping(){
        dinoStatus = .jumping
    }
    
    func bending(){
        dinoStatus = .bending
    }
    
    func idleStatus() {
        gameStatus = .idle
        traps.removeAllChildren()
        dino.position = CGPoint(x: self.frame.size.width * 0.20 ,y:self.frame.size.height * 0.8)
        dinoStartRun()
        movingObjects.speed = 0.5
        scoreLabelNode.text = "Tap screen to get started"
    }
    
    func runningStatus() {
        gameStatus = .running
        self.startCreateRandomTrees()
        meters = 0
        movingObjects.speed = originSpeed
    }
    
    func overStatus() {
        gameStatus = .over
        stopCreateTrees()
        movingObjects.speed = 0
        dinoStopRun()
    }
    
    /// SKPhysicsContact对象是包含着碰撞的两个物理体的,分别是bodyA和bodyB
    func didBegin(_ contact: SKPhysicsContact) {
        if gameStatus != .running {
            return
        }
        var bodyA : SKPhysicsBody
        var bodyB : SKPhysicsBody
//        print(contact.bodyA.categoryBitMask,contact.bodyB.categoryBitMask)
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        }else{
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        if(bodyA.categoryBitMask == dinoCategory && bodyB.categoryBitMask == floorCategory){
            if(dinoStatus == .jumping){
               running()
            }
        }
        if(bodyA.categoryBitMask == dinoCategory && bodyB.categoryBitMask == trapCategory){
            overStatus()
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(gameStatus == .running){
            meters += Int(1 * (movingObjects.speed))
            let times:Int = meters / 500
            if(times > 0){
                if(movingObjects.speed >= 5.0){
                    return
                }
                movingObjects.speed = originSpeed + CGFloat(times) * 0.5
            }
//            print(movingObjects.speed)
        }
    }
}
