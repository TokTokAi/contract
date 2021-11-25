// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";



contract Social is Initializable {
    struct Person {
        string username;
        string avatar;
        string description;
    }

    struct PostStatisic {
        uint32 likes;
        uint32 comments;
    }

  
    mapping(address => Person) private users;


    mapping(uint64 => address) private posters;


    mapping(uint64 => PostStatisic) private post_statistics;


    uint32 private next_event_id;
    uint32 private next_post_id;

    event Post(
        uint32 event_id,
        uint64 post_id, 
        address user_addr,
        string url,
        string cover, 
        string title
    );

    event Follow(
        uint32 event_id,
        address user_addr,
        address followed 
    );
    event Unfollow(
        uint32 event_id,
        address user_addr, 
        address followed 
    );

    event Like(
        uint32 event_id,
        address user_addr,
        uint64 post_id 
    );
    event Unlike(
        uint32 event_id,
        address user_addr,
        uint64 post_id
    );

    event Comment(
        uint32 event_id,
        address user_addr,
        uint64 post_id, 
        string content 
    );

    event UserProfile(
        uint32 event_id, 
        address user_addr,
        string username,
        string avatar,
        string description
    );

    function initialize() public initializer {
      next_event_id = 0;
      next_post_id = 0;
    }


    function set_profile(Person memory person) public {
        users[msg.sender] = person;
        emit UserProfile(get_event_id(), msg.sender, person.username, person.avatar, person.description);
    }


    function get_user(address addr) public view returns (Person memory) {
        return users[addr];
    }


    function post(string memory url, string memory cover, string memory title) public {
        uint64 id = next_post_id++;
        posters[id] = msg.sender;
        emit Post(get_event_id(), id, msg.sender, url, cover, title);
    }


    function comment(uint64 post_id, string memory content) public {
        post_statistics[post_id].comments += 1;
        emit Comment(get_event_id(), msg.sender, post_id, content);
    }

    function like(uint64 post_id) public {
        post_statistics[post_id].likes += 1;
        emit Like(get_event_id(), msg.sender, post_id);
    }

    function unlike(uint64 post_id) public {
        post_statistics[post_id].likes -= 1;
        emit Unlike(get_event_id(), msg.sender, post_id);
    }

    function follow(address target) public {
        emit Follow(get_event_id(), msg.sender, target);
    }

    function unfollow(address target) public {
        emit Unfollow(get_event_id(), msg.sender, target);
    }

    function get_event_id() private returns (uint32) {
        return next_event_id++;
    }
}
