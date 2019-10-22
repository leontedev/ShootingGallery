//
//  GameScene.swift
//  ShootingGallery
//
//  Created by Mihai Leonte on 10/15/19.
//  Copyright © 2019 Mihai Leonte. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var asteroidTimer: Timer?
    var ufoTimer: Timer?
    var ammoTimer: Timer?
    var starfield: SKEmitterNode!
    var ammoNodes: [SKShapeNode] = []
    var ammo: Int = 5 {
        didSet {
            // Draw ammo UI
            if ammo == 0 {
                ammoTimer?.invalidate()
                ammoTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(reloadAmmo), userInfo: nil, repeats: false)
            }
            
            for node in ammoNodes {
                node.removeFromParent()
            }
            ammoNodes.removeAll()
            
            for number in 1...5 {
                let circle = SKShapeNode(circleOfRadius: 8)
                if number <= ammo {
                    circle.fillColor = SKColor.yellow
                    circle.lineWidth = 1
                    circle.strokeColor = SKColor.yellow
                } else {
                    circle.fillColor = SKColor.clear
                    circle.lineWidth = 1
                    circle.strokeColor = SKColor.red
                }
                circle.position = CGPoint(x: self.size.width - 30 - CGFloat(17 * number), y: self.size.height - 30)
                self.addChild(circle)
                ammoNodes.append(circle)
            }
            
        }
    }
    var timeInterval = Double.random(in: 1...2)
    var debrisList = ["asteroid1", "asteroid_small", "asteroid_large"]
    var ufoList = ["alien1", "alien2"]
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
        
    var gameoverLabel: SKLabelNode!
    var isGameOver = false {
        didSet {
            if isGameOver {
                gameoverLabel = SKLabelNode(fontNamed: "Chalkduster")
                gameoverLabel.position = CGPoint(x: 512, y: 430)
                gameoverLabel.horizontalAlignmentMode = .center
                gameoverLabel.verticalAlignmentMode = .center
                gameoverLabel.text = "Game Over!  Tap to start"
                gameoverLabel.numberOfLines = 0
                gameoverLabel.preferredMaxLayoutWidth = 250
                addChild(gameoverLabel)
            }
//            for child in self.children {
//                if child.name == "asteroid" {
//                    child.removeFromParent()
//                }
//            }
        }
    }
    

    
    override func didMove(to view: SKView) {
        
        backgroundColor = .black
        starfield = SKEmitterNode(fileNamed: "starfield")!
        starfield.position = CGPoint(x: 1024, y: 384)
        // to have stars fill up the screen right from the start:
        starfield.advanceSimulationTime(20)
        addChild(starfield)
        starfield.zPosition = -1
        
        // Remove default gravity
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        startGame()
    }
    
    @objc func reloadAmmo() {
        ammo = 5
    }
    
    func startGame() {
        if let label = gameoverLabel {
            label.removeFromParent()
        }
        isGameOver = false
        ammo = 5
        // Add UFO
        let player = SKSpriteNode(imageNamed: "player_spaceship")
        player.position = CGPoint(x: 512, y: 384)
        player.name = "player"
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.contactTestBitMask = 1
        addChild(player)
        score = 0
        asteroidTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(createAsteroid), userInfo: nil, repeats: false)
        ufoTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(createUFO), userInfo: nil, repeats: false)
    }
    
    @objc func createUFO() {
        guard let artefact = ufoList.randomElement() else { return }
        
        let randomPositionIsLeft = Bool.random()
        
        let sprite = SKSpriteNode(imageNamed: artefact)
        sprite.name = "ufo"
        if randomPositionIsLeft {
            sprite.position = CGPoint(x: -200, y: Int.random(in: 130...230))
        } else {
            sprite.position = CGPoint(x: 1200, y: Int.random(in: 550...650))
        }
        addChild(sprite)
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        // to collide with an asteroid
        sprite.physicsBody?.contactTestBitMask = 1
        if randomPositionIsLeft {
            sprite.physicsBody?.velocity = CGVector(dx: 100, dy: 0)
        } else {
            sprite.physicsBody?.velocity = CGVector(dx: -700, dy: 0)
        }
        sprite.physicsBody?.angularDamping = 0
        sprite.physicsBody?.linearDamping = 0
        
        
        ufoTimer?.invalidate()
        timeInterval = Double.random(in: 0.2...3)
        ufoTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(createUFO), userInfo: nil, repeats: false)
    }
    
    @objc func createAsteroid() {
        guard let artefact = debrisList.randomElement() else { return }
        
        let sprite = SKSpriteNode(imageNamed: artefact)
        
        // randomly generate the initial position to be from any angle, outside of the screen
        var outofbounds = false
        var x = Int.random(in: -300...1300)
        var y = Int.random(in: -300...1000)
        while !outofbounds {
            if x > 1100 || x < -100 || y > 850 || y < -100 {
                outofbounds.toggle()
            } else {
                x = Int.random(in: -300...1300)
                y = Int.random(in: -300...1000)
            }
        }
        
        //print("x: \(x) and y: \(y)")
        
        sprite.position = CGPoint(x: x, y: y)
        sprite.name = "asteroid"
        addChild(sprite)
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        // to collide with the player
        sprite.physicsBody?.categoryBitMask = 1
        
        // slow down the asteroid by a factor
        let randomSpeedFactor = Double.random(in: 2...4)
        // add a random variation so the asteroid doesn't always come straight towards the center
        let dx: Double = (512 - Double(x)) / randomSpeedFactor + Double.random(in: -80...80)
        let dy: Double = (384 - Double(y)) / randomSpeedFactor + Double.random(in: -60...60)
        sprite.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
        
        // add spin
        sprite.physicsBody?.angularVelocity = CGFloat.random(in: -15...15)
        sprite.physicsBody?.angularDamping = 0
        sprite.physicsBody?.linearDamping = 0
        
        // randomize next asteroid init
        asteroidTimer?.invalidate()
        timeInterval = Double.random(in: 0.75...2)
        asteroidTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(createAsteroid), userInfo: nil, repeats: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if isGameOver {
            startGame()
        } else {
            if ammo > 0 {
                ammo -= 1

                for node in nodes(at: touch.location(in: self)) {
                    if node.name == "asteroid" {
                        node.removeFromParent()
                        score += 1
                    }
                }
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if abs(node.position.x) > 1200 || abs(node.position.y) > 1200 {
                node.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "player" || nodeB.name == "player" || nodeA.name == "ufo" || nodeB.name == "ufo"{
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            
            let explosion = SKEmitterNode(fileNamed: "Explosion")!
            
            if nodeA.name == "player" || nodeA.name == "ufo" {
                explosion.position = nodeA.position
            } else {
                explosion.position = nodeB.position
            }
            
            addChild(explosion)
            if nodeA.name == "player" || nodeB.name == "player" {
                isGameOver = true
                asteroidTimer?.invalidate()
                ufoTimer?.invalidate()
            }
            
        }
    }
}
