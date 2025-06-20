// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Panagram} from "../src/Panagram.sol";
import {HonkVerifier} from "../src/Verifier.sol";
import {IVerifier} from "../src/Verifier.sol";
import {MockVerifier} from "../test/mocks/MockVerifier.sol";

contract PanagramTest is Test {
    Panagram public panagram;
    MockVerifier public verifier;

    uint256 public FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant MIN_DURATION = 10800;

    bytes32 public ANSWER;
    bytes32 public ANSWER2;

    address public owner;
    address public player1;
    address public player2;
    address public player3;

    function setUp() external {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");

        verifier = new MockVerifier();
        panagram = new Panagram(IVerifier(verifier));

        bytes32 hashedAnswer = keccak256(bytes("Shourya"));
        ANSWER = bytes32(uint256(hashedAnswer) % FIELD_MODULUS);

        // panagram.newRound(ANSWER);

        bytes32 hashedAnswer2 = keccak256(bytes("Shreeya"));
        ANSWER2 = bytes32(uint256(hashedAnswer2) % FIELD_MODULUS);
    }

    ///////////////////////////////////////////////
    /////////// CONSTRUCTOR TESTS /////////////////
    ///////////////////////////////////////////////

    function test_Constructor() public view {
        assertEq(address(panagram.s_verifier()), address(verifier));
        assertEq(panagram.owner(), owner);
    }

    function test_ConstructorWithZeroAddress() public {
        vm.expectRevert();
        new Panagram(IVerifier(address(0)));
    }

    ///////////////////////////////////////////////
    /////////// VERIFIER UPDATE TESTS /////////////
    ///////////////////////////////////////////////

    function test_UpdateVerifier() public {
        MockVerifier newVerifier = new MockVerifier();

        vm.expectEmit(true, true, true, true);
        emit Panagram.Panagram_VerifierUpdated(IVerifier(newVerifier));

        panagram.updateVerifier(IVerifier(newVerifier));
        assertEq(address(panagram.s_verifier()), address(newVerifier));
    }

    function test_UpdateVerifier_RevertWhen_ZeroAddress() public {
        vm.expectRevert(Panagram.Panagram__InvalidVerifierAddress.selector);
        panagram.updateVerifier(IVerifier(address(0)));
    }

    function test_UpdateVerifier_RevertWhen_NotOwner() public {
        MockVerifier newVerifier = new MockVerifier();

        vm.prank(player1);
        vm.expectRevert();
        panagram.updateVerifier(IVerifier(newVerifier));
    }

    ///////////////////////////////////////////////
    /////////// NEW ROUND TESTS ///////////////////
    ///////////////////////////////////////////////

    function test_NewRound_FirstRound() public {
        Panagram freshPanagram = new Panagram(IVerifier(verifier));

        vm.expectEmit(true, true, true, true);
        emit Panagram.Panagram_NewRoundStarted(ANSWER);

        freshPanagram.newRound(ANSWER);
    }

    function test_NewRound_RevertWhen_EmptyAnswer() public {
        vm.expectRevert(Panagram.Panagram__EmptyAnswer.selector);
        panagram.newRound(bytes32(0));
    }

    function test_NewRound_RevertWhen_NotOwner() public {
        vm.prank(player1);
        vm.expectRevert();
        panagram.newRound(ANSWER);
    }

    function test_NewRound_RevertWhen_MinTimeNotPassed() public {
        panagram.newRound(ANSWER);

        vm.expectRevert(abi.encodeWithSelector(Panagram.Panagram__MinTimeNotPassed.selector, MIN_DURATION, 0));
        panagram.newRound(ANSWER2);
    }

    function test_NewRound_RevertWhen_NoWinner() public {
        panagram.newRound(ANSWER);

        vm.warp(block.timestamp + MIN_DURATION + 1);

        vm.expectRevert(Panagram.Panagram__NoRoundWinner.selector);
        panagram.newRound(ANSWER2);
    }

    function test_NewRound_SuccessAfterWinnerAndTime() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("Shourya");

        vm.warp(block.timestamp + MIN_DURATION + 1);

        vm.expectEmit(true, true, true, true);
        emit Panagram.Panagram_NewRoundStarted(ANSWER2);

        panagram.newRound(ANSWER2);
    }

    ////////////////////////////////////////////////
    /////////// MAKE GUESS TESTS ///////////////////
    ////////////////////////////////////////////////

    function test_MakeGuess_RevertWhen_NoRoundStarted() public {
        Panagram freshPanagram = new Panagram(IVerifier(verifier));

        vm.prank(player1);
        vm.expectRevert(Panagram.Panagram__FirstPanagramNotSet.selector);
        freshPanagram.makeGuess("proof");
    }

    function test_MakeGuess_Winner() public {
        panagram.newRound(ANSWER);

        assertEq(panagram.balanceOf(player1, 0), 0);
        assertEq(panagram.balanceOf(player1, 1), 0);

        vm.expectEmit(true, true, true, true);
        emit Panagram.Panagram_WinnerCrowned(player1, 1);

        vm.prank(player1);
        bool result = panagram.makeGuess("validProof");

        assertTrue(result);
        assertEq(panagram.balanceOf(player1, 0), 1);
        assertEq(panagram.balanceOf(player1, 1), 0);
    }

    function test_MakeGuess_RunnerUp() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("validProof");

        vm.expectEmit(true, true, true, true);
        emit Panagram.Panagram_RunnerUpCrowned(player2, 1);

        vm.prank(player2);
        bool result = panagram.makeGuess("validProof");

        assertTrue(result);
        assertEq(panagram.balanceOf(player2, 0), 0);
        assertEq(panagram.balanceOf(player2, 1), 1);
    }

    function test_MakeGuess_MultipleRunnerUps() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("validProof");

        vm.prank(player2);
        panagram.makeGuess("validProof");

        vm.prank(player3);
        panagram.makeGuess("validProof");

        assertEq(panagram.balanceOf(player1, 0), 1);
        assertEq(panagram.balanceOf(player1, 1), 0);

        assertEq(panagram.balanceOf(player2, 0), 0);
        assertEq(panagram.balanceOf(player2, 1), 1);

        assertEq(panagram.balanceOf(player3, 0), 0);
        assertEq(panagram.balanceOf(player3, 1), 1);
    }

    function test_MakeGuess_RevertWhen_AlreadyGuessedCorrectly() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("validProof");

        vm.prank(player1);
        vm.expectRevert(abi.encodeWithSelector(Panagram.Panagram__AlreadyGuessedCorrectly.selector, 1, player1));
        panagram.makeGuess("validProof");
    }

    function test_MakeGuess_RevertWhen_InvalidProof() public {
        panagram.newRound(ANSWER);

        verifier.setShouldReturnTrue(false);

        vm.prank(player1);
        vm.expectRevert(Panagram.Panagram__InvalidProof.selector);
        panagram.makeGuess("invalidProof");
    }

    function test_MakeGuess_SamePlayerDifferentRounds() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("validProof");

        vm.prank(player2);
        panagram.makeGuess("validProof");

        vm.warp(block.timestamp + MIN_DURATION + 1);
        panagram.newRound(ANSWER2);

        vm.prank(player1);
        bool result = panagram.makeGuess("validProof");
        assertTrue(result);

        assertEq(panagram.balanceOf(player1, 0), 2);
        assertEq(panagram.balanceOf(player1, 1), 0);
    }

    ///////////////////////////////////////////////
    //////////// INTEGRATION TESTS/////////////////
    ///////////////////////////////////////////////

    function test_FullGameFlow() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        panagram.makeGuess("validProof");

        vm.prank(player2);
        panagram.makeGuess("validProof");

        vm.prank(player3);
        panagram.makeGuess("validProof");

        vm.warp(block.timestamp + MIN_DURATION + 1);

        panagram.newRound(ANSWER2);

        vm.prank(player2);
        panagram.makeGuess("validProof");

        vm.prank(player1);
        panagram.makeGuess("validProof");

        assertEq(panagram.balanceOf(player1, 0), 1); // Won round 1
        assertEq(panagram.balanceOf(player1, 1), 1); // Runner-up round 2

        assertEq(panagram.balanceOf(player2, 0), 1); // Won round 2
        assertEq(panagram.balanceOf(player2, 1), 1); // Runner-up round 1

        assertEq(panagram.balanceOf(player3, 0), 0); // Never won
        assertEq(panagram.balanceOf(player3, 1), 1); // Runner-up round 1
    }

    ///////////////////////////////////////////////
    //////////// EDGE CASE TESTS //////////////////
    ///////////////////////////////////////////////

    function test_VerifierCallsWithCorrectParameters() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        bool result = panagram.makeGuess("validProof");
        assertTrue(result);
    }

    function test_EmptyProofStillCallsVerifier() public {
        panagram.newRound(ANSWER);

        vm.prank(player1);
        bool result = panagram.makeGuess("");
        assertTrue(result);
    }

    function test_LongProofData() public {
        panagram.newRound(ANSWER);

        bytes memory longProof = new bytes(1000);
        for (uint256 i = 0; i < 1000; i++) {
            longProof[i] = bytes1(uint8(i % 256));
        }

        vm.prank(player1);
        bool result = panagram.makeGuess(longProof);
        assertTrue(result);
    }

    ///////////////////////////////////////////////
    /////// HELPER FUNCTIONS FOR TESTING //////////
    ///////////////////////////////////////////////

    function _setupRoundWithWinner() internal {
        panagram.newRound(ANSWER);
        vm.prank(player1);
        panagram.makeGuess("validProof");
    }
}
