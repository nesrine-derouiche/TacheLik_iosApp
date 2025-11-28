import SpriteKit
import GameplayKit

protocol CodeRunnerGameDelegate: AnyObject {
    func gameDidEnd(score: Int)
    func scoreDidUpdate(score: Int)
    func didSpawnQuestion(_ question: GameQuestion)
}

class CodeRunnerScene: SKScene, SKPhysicsContactDelegate {
    
    weak var gameDelegate: CodeRunnerGameDelegate?
    
    private var player: SKSpriteNode!
    private var background1: SKSpriteNode!
    private var background2: SKSpriteNode!
    
    private var currentLane: Int = 1 // 0: Left, 1: Center, 2: Right
    private let laneCount = 3
    private var laneWidth: CGFloat = 0
    
    private var score = 0 {
        didSet {
            gameDelegate?.scoreDidUpdate(score: score)
        }
    }
    
    private var isGameOver = false
    private var gameSpeed: CGFloat = 180 // Reduced from 250 to 180 (even slower)
    private var lastUpdateTime: TimeInterval = 0
    private var obstacleSpawnTimer: TimeInterval = 0
    private let obstacleSpawnInterval: TimeInterval = 7.0 // Increased from 4.5 to 7.0 (much longer distance)
    
    private let playerCategory: UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    
    override func didMove(to view: SKView) {
        // Set anchor point to center so (0,0) is the middle of the screen
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupPhysics()
        setupBackground()
        setupPlayer()
        
        laneWidth = size.width / 3
        
        // Initial spawn with a delay to allow UI to settle and user to read the first question
        run(SKAction.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                self?.spawnObstacleRow()
            }
        ]))
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func setupBackground() {
        // Create two background nodes for infinite scrolling
        // Use the correct asset name "game_background"
        let bgTexture = SKTexture(imageNamed: "game_background")
        
        func createBg() -> SKSpriteNode {
            let bg = SKSpriteNode(texture: bgTexture)
            bg.size = CGSize(width: size.width, height: size.height)
            bg.position = CGPoint(x: 0, y: 0)
            bg.zPosition = -1
            return bg
        }
        
        background1 = createBg()
        background1.position = CGPoint(x: 0, y: 0)
        addChild(background1)
        
        background2 = createBg()
        background2.position = CGPoint(x: 0, y: background1.size.height)
        addChild(background2)
    }
    
    private func setupPlayer() {
        // Load animation textures
        let runTextures = [
            SKTexture(imageNamed: "player_run_0"),
            SKTexture(imageNamed: "player_run_1"),
            SKTexture(imageNamed: "player_run_2"),
            SKTexture(imageNamed: "player_run_3")
        ]
        
        // Create player with the first frame
        player = SKSpriteNode(texture: runTextures[0])
        player.size = CGSize(width: 80, height: 80) // Slightly larger for the new sprite
        player.position = CGPoint(x: 0, y: -size.height / 3)
        player.zPosition = 1
        
        // Run animation action
        let animation = SKAction.animate(with: runTextures, timePerFrame: 0.1)
        player.run(SKAction.repeatForever(animation))
        
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 60)) // Smaller hitbox than visual size
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = obstacleCategory
        player.physicsBody?.collisionBitMask = 0 // No physical collision response
        player.physicsBody?.isDynamic = true
        
        addChild(player)
    }
    
    // MARK: - Input Handling
    
    private var touchStartX: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartX = touch.location(in: self).x
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchEndX = touch.location(in: self).x
        let diff = touchEndX - touchStartX
        
        if abs(diff) > 20 { // Threshold for swipe
            if diff > 0 {
                moveRight()
            } else {
                moveLeft()
            }
        }
    }
    
    private func moveLeft() {
        if currentLane > 0 {
            currentLane -= 1
            updatePlayerPosition()
        }
    }
    
    private func moveRight() {
        if currentLane < laneCount - 1 {
            currentLane += 1
            updatePlayerPosition()
        }
    }
    
    private func updatePlayerPosition() {
        let xOffset = (CGFloat(currentLane) - 1) * laneWidth
        let moveAction = SKAction.moveTo(x: xOffset, duration: 0.2)
        moveAction.timingMode = .easeOut
        player.run(moveAction)
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateBackground(dt: dt)
        updateObstacles(dt: dt)
        
        obstacleSpawnTimer += dt
        if obstacleSpawnTimer >= obstacleSpawnInterval {
            obstacleSpawnTimer = 0
            spawnObstacleRow()
            
            // Increase speed very slightly over time (reduced from 2 to 1)
            gameSpeed += 1
        }
    }
    
    private func updateBackground(dt: TimeInterval) {
        let moveAmount = gameSpeed * CGFloat(dt)
        background1.position.y -= moveAmount
        background2.position.y -= moveAmount
        
        if background1.position.y <= -background1.size.height {
            background1.position.y = background2.position.y + background2.size.height
        }
        
        if background2.position.y <= -background2.size.height {
            background2.position.y = background1.position.y + background1.size.height
        }
    }
    
    private func updateObstacles(dt: TimeInterval) {
        enumerateChildNodes(withName: "obstacle") { node, _ in
            node.position.y -= self.gameSpeed * CGFloat(dt)
            if node.position.y < -self.size.height / 2 - 100 {
                node.removeFromParent()
            }
        }
    }
    
    private func spawnObstacleRow() {
        guard let question = GameQuestionProvider.shared.getRandomQuestion() else {
            // No questions available, end game
            gameOver()
            return
        }
        
        // Notify delegate of the new question
        gameDelegate?.didSpawnQuestion(question)
        
        // Spawn 3 gates
        for i in 0..<3 {
            let gate = createGate(text: question.options[i], isCorrect: i == question.correctOptionIndex)
            let xOffset = (CGFloat(i) - 1) * laneWidth
            // Spawn higher up so the user has time to read the question on the UI
            gate.position = CGPoint(x: xOffset, y: size.height / 2 + 600)
            addChild(gate)
        }
    }
    
    private func createGate(text: String, isCorrect: Bool) -> SKNode {
        let container = SKNode()
        container.name = "obstacle"
        
        let boxSize = CGSize(width: laneWidth - 20, height: 120)
        let box = SKShapeNode(rectOf: boxSize, cornerRadius: 16)
        
        // Make it look like a futuristic gate
        box.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.8)
        box.strokeColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Cyan glow
        box.lineWidth = 3
        box.glowWidth = 5
        
        container.addChild(box)
        
        let label = SKLabelNode(fontNamed: "Nunito-Bold")
        label.text = text
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = boxSize.width - 20
        label.numberOfLines = 3
        
        container.addChild(label)
        
        // Physics body for collision
        let pb = SKPhysicsBody(rectangleOf: boxSize)
        pb.categoryBitMask = obstacleCategory
        pb.contactTestBitMask = playerCategory
        pb.collisionBitMask = 0
        pb.isDynamic = false
        container.physicsBody = pb
        
        // Store correctness in userData
        container.userData = NSMutableDictionary()
        container.userData?.setValue(isCorrect, forKey: "isCorrect")
        
        return container
    }
    
    // MARK: - Collision
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        
        let otherBody = contact.bodyA.categoryBitMask == playerCategory ? contact.bodyB : contact.bodyA
        guard let obstacleNode = otherBody.node else { return }
        
        if let isCorrect = obstacleNode.userData?.value(forKey: "isCorrect") as? Bool {
            if isCorrect {
                // Correct answer
                score += 10
                // run(SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false))
                
                // Visual feedback
                if let shape = obstacleNode.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
                    shape.fillColor = UIColor.green.withAlphaComponent(0.5)
                    shape.strokeColor = .green
                }
                
                // Disable collision for this node so we don't hit it again
                obstacleNode.physicsBody?.categoryBitMask = 0
                
            } else {
                // Wrong answer
                gameOver()
                
                if let shape = obstacleNode.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
                    shape.fillColor = UIColor.red.withAlphaComponent(0.5)
                    shape.strokeColor = .red
                }
            }
        }
    }
    
    private func gameOver() {
        isGameOver = true
        gameDelegate?.gameDidEnd(score: score)
        
        // Explosion effect?
        // For now just stop everything
        self.isPaused = true
    }
}
