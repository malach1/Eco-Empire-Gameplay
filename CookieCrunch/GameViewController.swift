//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Matthijs on 19-06-14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

var directionOfSwipe = String()
var rowColumn = Int()



class GameViewController: UIViewController {
  // The scene draws the tiles and cookie sprites, and handles swipes.
  var scene: GameScene!

  // The level contains the tiles, the cookies, and most of the gameplay logic.
  // Needs to be ! because it's not set in init() but in viewDidLoad().
  var level: Level!

  var movesLeft = 0
  var score = 0

  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var shuffleButton: UIButton!

  var tapGestureRecognizer: UITapGestureRecognizer!

  lazy var backgroundMusic: AVAudioPlayer = {
    let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3")
    let player = try? AVAudioPlayer(contentsOfURL: url!)
    player!.numberOfLoops = -1
    return player!
  }()

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

  override func shouldAutorotate() -> Bool {
    return true
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.AllButUpsideDown
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Configure the view.
    let skView = view as! SKView
    skView.multipleTouchEnabled = false

    // Create and configure the scene.
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .AspectFill

    // Load the level.
    level = Level(filename: "Level_0")
    scene.level = level
    scene.addTiles()
    scene.swipeHandler = handleSwipe

    // Hide the game over panel from the screen.
    gameOverPanel.hidden = true
    shuffleButton.hidden = true

    // Present the scene.
    skView.presentScene(scene)

    // Load and start background music.
    //backgroundMusic.play()

    // Let's start the game!
    beginGame()
    //shuffle()
  }

  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    updateLabels()

    level.resetComboMultiplier()

    scene.animateBeginGame() {
      self.shuffleButton.hidden = false
    }

    shuffle()
  }

  func shuffle() {
    // Delete the old cookie sprites, but not the tiles.
    scene.removeAllCookieSprites()

    // Fill up the level with new cookies, and create sprites for them.
    let newCookies = level.shuffle()
    scene.addSpritesForCookies(newCookies)
  }

   // MARK: Handle Swipe
  // This is the swipe handler. MyScene invokes this function whenever it
  // detects that the player performs a swipe.
  func handleSwipe(swap: Swap) {
    // While cookies are being matched and new cookies fall down to fill up
    // the holes, we don't want the player to tap on anything.
    view.userInteractionEnabled = false

    handleRowColumnRemoval()
    
    self.view.userInteractionEnabled = true
  }
    
    func handleRowColumnRemoval() {
        // Detect if there are any matches left.
        let chains = level.removeRowColumn()
        
        // If there are no more matches, then the player gets to move again.
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        
        // First, remove any matches...
        scene.animateMatchedCookies(chains) {
            self.updateLabels()
            
            // ...and finally, add new cookies at the top.
            let columns = self.level.topUpCookies()
            self.scene.animateReplaceCookies(columns) {

                
                // ...then shift down any cookies that have a hole below them...
                let columns = self.level.fillHoles()
                self.scene.animateFallingCookies(columns) {

                    
                    // Keep repeating this cycle until there are no more matches.
                    //self.handleMatches()
               }
            }
        }
    }

  // This is the main loop that removes any matching cookies and fills up the
  // holes with new cookies. While this happens, the user cannot interact with
  // the app.
  func handleMatches() {
    // Detect if there are any matches left.
    let chains = level.removeMatches()

    //print(chains)
    
    // If there are no more matches, then the player gets to move again.
    if chains.count == 0 {
      beginNextTurn()
      return
    }

    // First, remove any matches...
    scene.animateMatchedCookies(chains) {
    print("remove matches: \(chains)")
      // Add the new scores to the total.
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()

      // ...then shift down any cookies that have a hole below them...
      var columns = self.level.fillHoles()
       print("fill holes: \(columns)")
        self.scene.animateFallingCookies(columns) {

        // ...and finally, add new cookies at the top.
        let columns = self.level.topUpCookies()
        print("topUpCookies: \(columns)")
        self.scene.animateNewCookies(columns) {

          // Keep repeating this cycle until there are no more matches.
          self.handleMatches()
        }
      }
    }
  }

  func beginNextTurn() {
    level.resetComboMultiplier()
    level.detectPossibleSwaps()
    view.userInteractionEnabled = true
    decrementMoves()
  }

  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
  }

  func decrementMoves() {
    --movesLeft
    updateLabels()

    if score >= level.targetScore {
      gameOverPanel.image = UIImage(named: "LevelComplete")
      showGameOver()
    } else if movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOver()
    }
  }

  func showGameOver() {
    gameOverPanel.hidden = false
    scene.userInteractionEnabled = false
    shuffleButton.hidden = true

    scene.animateGameOver() {
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameOver")
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
  }

  func hideGameOver() {
    view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil

    gameOverPanel.hidden = true
    scene.userInteractionEnabled = true

    beginGame()
  }

  @IBAction func shuffleButtonPressed(_: AnyObject) {
    shuffle()

    // Pressing the shuffle button costs a move.
    decrementMoves()
  }
}
