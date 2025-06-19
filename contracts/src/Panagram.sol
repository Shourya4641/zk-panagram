//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVerifier} from "src/Verifier.sol";

/**
 * @title Panagram Contract
 * @author Shourya
 * @notice The Panagram contract is designed as an engaging on-chain game where users submit proofs to solve a puzzle each round, with NFT rewards for winners and participants.
 */
contract Panagram is ERC1155, Ownable {
    error Panagram__InvalidVerifierAddress();
    error Panagram__EmptyAnswer();
    error Panagram__MinTimeNotPassed(uint256 minRoundDuration, uint256 passedTime);
    error Panagram__NoRoundWinner();
    error Panagram__FirstPanagramNotSet();
    error Panagram__AlreadyGuessedCorrectly(uint256 roundNumber, address player);
    error Panagram__InvalidProof();

    IVerifier public s_verifier;
    uint256 private constant MIN_DURATION = 10800;
    uint256 private s_roundStartTime;
    address private s_currentRoundWinner;
    bytes32 private s_answer;
    uint256 private s_currentRound;

    mapping(address player => uint256 roundNumber) private s_lastCorrectGuessRound;

    event Panagram_VerifierUpdated(IVerifier verifier);
    event Panagram_NewRoundStarted(bytes32 answer);
    event Panagram_WinnerCrowned(address indexed winner, uint256 round);
    event Panagram_RunnerUpCrowned(address indexed runnerUp, uint256 round);

    constructor(IVerifier _verifier)
        ERC1155("ipfs://bafybeicqfc4ipkle34tgqv3gh7gccwhmr22qdg7p6k6oxon255mnwb6csi/{id}.json")
        Ownable(msg.sender)
    {
        s_verifier = _verifier;
        s_roundStartTime = 0;
        s_currentRound = 0;
        s_currentRoundWinner = address(0);
    }

    ///////////////////////EXTERNAL FUNCTIONS//////////////////////
    function updateVerifier(IVerifier _verifier) external onlyOwner {
        if (address(_verifier) == address(0)) {
            revert Panagram__InvalidVerifierAddress();
        }

        s_verifier = _verifier;
        emit Panagram_VerifierUpdated(_verifier);
    }

    function newRound(bytes32 _answer) external onlyOwner {
        if (_answer == bytes32(0)) {
            revert Panagram__EmptyAnswer();
        }

        if (s_roundStartTime == 0) {
            s_roundStartTime = block.timestamp;
            s_answer = _answer;
        } else {
            if (block.timestamp < s_roundStartTime + MIN_DURATION) {
                revert Panagram__MinTimeNotPassed(MIN_DURATION, block.timestamp - s_roundStartTime);
            }

            if (s_currentRoundWinner == address(0)) {
                revert Panagram__NoRoundWinner();
            }

            s_roundStartTime = block.timestamp;
            s_currentRoundWinner = address(0);
            s_answer = _answer;
        }

        s_currentRound++;

        emit Panagram_NewRoundStarted(_answer);
    }

    function makeGuess(bytes memory _proof) external returns (bool) {
        if (s_currentRound == 0) {
            revert Panagram__FirstPanagramNotSet();
        }

        if (s_lastCorrectGuessRound[msg.sender] == s_currentRound) {
            revert Panagram__AlreadyGuessedCorrectly(s_currentRound, msg.sender);
        }

        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = s_answer;

        bool result = s_verifier.verify(_proof, publicInputs);

        if (!result) {
            revert Panagram__InvalidProof();
        }

        s_lastCorrectGuessRound[msg.sender] = s_currentRound;

        if (s_currentRoundWinner == address(0)) {
            s_currentRoundWinner = msg.sender;
            _mint(msg.sender, 0, 1, "");
            emit Panagram_WinnerCrowned(msg.sender, s_currentRound);
        } else {
            _mint(msg.sender, 1, 1, "");
            emit Panagram_RunnerUpCrowned(msg.sender, s_currentRound);
        }

        return true;
    }
}
