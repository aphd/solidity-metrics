// File: contracts/Contracts.sol

pragma solidity >=0.5.0 <0.6.0;

contract Ballot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;
    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            &quot;Only chairperson can give right to vote.&quot;
        );
        require(
            !voters[voter].voted,
            &quot;The voter already voted.&quot;
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, &quot;You already voted.&quot;);

        require(to != msg.sender, &quot;Self-delegation is disallowed.&quot;);

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, &quot;Found loop in delegation.&quot;);
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, &quot;Has no right to vote&quot;);
        require(!sender.voted, &quot;Already voted.&quot;);
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

}

contract Foo {
  string public foo;

  function getFoo() public {
    string memory _foo = foo;
    string memory _bar = foo;
  }
}