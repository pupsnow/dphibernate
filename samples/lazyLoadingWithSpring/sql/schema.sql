# --------------------------------------------------------
# Host:                         127.0.0.1
# Database:                     so
# Server version:               5.1.40-community
# Server OS:                    Win64
# HeidiSQL version:             5.0.0.3272
# Date/time:                    2010-07-05 23:39:24
# --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
# Dumping database structure for so
CREATE DATABASE IF NOT EXISTS `pepper` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `pepper`;


# Dumping structure for table so.applicationusers
CREATE TABLE IF NOT EXISTS `applicationusers` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_Username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.badges
CREATE TABLE IF NOT EXISTS `badges` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(40) CHARACTER SET utf8 NOT NULL,
  `UserId` int(11) NOT NULL,
  `Date` datetime NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `FK_badges_users` (`UserId`),
  KEY `FKACC0D9304F235592` (`user_id`),
  CONSTRAINT `FKACC0D9304F235592` FOREIGN KEY (`user_id`) REFERENCES `users` (`Id`),
  CONSTRAINT `FK_badges_users` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.comments
CREATE TABLE IF NOT EXISTS `comments` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `CreationDate` datetime NOT NULL,
  `PostId` int(11) NOT NULL,
  `Score` int(11) DEFAULT NULL,
  `Text` longtext,
  `UserId` int(11) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `FKDC17DDF41D571213` (`PostId`),
  KEY `FKDC17DDF4261399A9` (`UserId`),
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comments_ibfk_3` FOREIGN KEY (`PostId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FKDC17DDF41D571213` FOREIGN KEY (`PostId`) REFERENCES `posts` (`Id`),
  CONSTRAINT `FKDC17DDF4261399A9` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.posts
CREATE TABLE IF NOT EXISTS `posts` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `AcceptedAnswerId` int(11) DEFAULT NULL,
  `AnswerCount` int(11) DEFAULT NULL,
  `Body` longtext CHARACTER SET utf8 NOT NULL,
  `ClosedDate` datetime DEFAULT NULL,
  `CommentCount` int(11) DEFAULT NULL,
  `CommunityOwnedDate` datetime DEFAULT NULL,
  `CreationDate` datetime NOT NULL,
  `FavoriteCount` int(11) DEFAULT NULL,
  `LastActivityDate` datetime NOT NULL,
  `LastEditDate` datetime DEFAULT NULL,
  `LastEditorDisplayName` varchar(40) CHARACTER SET utf8 DEFAULT NULL,
  `LastEditorUserId` int(11) DEFAULT NULL,
  `OwnerUserId` int(11) DEFAULT NULL,
  `ParentId` int(11) DEFAULT NULL,
  `PostTypeId` int(11) NOT NULL,
  `Score` int(11) NOT NULL,
  `Tags` varchar(150) CHARACTER SET utf8 DEFAULT NULL,
  `Title` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `ViewCount` int(11) NOT NULL,
  PRIMARY KEY (`Id`),
  KEY `PostTypeId` (`PostTypeId`),
  KEY `LastEditorUserId` (`LastEditorUserId`),
  KEY `ParentId` (`ParentId`),
  KEY `AcceptedAnswerId` (`AcceptedAnswerId`),
  KEY `FK65E7BD383257A1C` (`OwnerUserId`),
  CONSTRAINT `FK65E7BD383257A1C` FOREIGN KEY (`OwnerUserId`) REFERENCES `users` (`Id`),
  CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`OwnerUserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `posts_ibfk_2` FOREIGN KEY (`PostTypeId`) REFERENCES `posttypes` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `posts_ibfk_3` FOREIGN KEY (`LastEditorUserId`) REFERENCES `users` (`Id`),
  CONSTRAINT `posts_ibfk_4` FOREIGN KEY (`ParentId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `posts_ibfk_5` FOREIGN KEY (`AcceptedAnswerId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.posttags
CREATE TABLE IF NOT EXISTS `posttags` (
  `PostId` int(11) NOT NULL,
  `Tag` varchar(50) CHARACTER SET utf8 NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `PostId` (`PostId`),
  CONSTRAINT `posttags_ibfk_1` FOREIGN KEY (`PostId`) REFERENCES `posts` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.posttypes
CREATE TABLE IF NOT EXISTS `posttypes` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(10) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.post_replies
CREATE TABLE IF NOT EXISTS `post_replies` (
  `postId` int(10) NOT NULL AUTO_INCREMENT,
  `replyId` int(10) NOT NULL,
  PRIMARY KEY (`postId`,`replyId`),
  KEY `replyId` (`replyId`),
  CONSTRAINT `post_replies_ibfk_1` FOREIGN KEY (`postId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `post_replies_ibfk_2` FOREIGN KEY (`replyId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.userposts
CREATE TABLE IF NOT EXISTS `userposts` (
  `userId` int(11) NOT NULL AUTO_INCREMENT,
  `postId` int(11) NOT NULL,
  PRIMARY KEY (`userId`,`postId`),
  KEY `postId` (`postId`),
  CONSTRAINT `userposts_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `userposts_ibfk_2` FOREIGN KEY (`postId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.users
CREATE TABLE IF NOT EXISTS `users` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `AboutMe` longtext,
  `Age` int(11) DEFAULT NULL,
  `CreationDate` datetime NOT NULL,
  `DisplayName` varchar(40) CHARACTER SET utf8 NOT NULL,
  `DownVotes` int(11) NOT NULL,
  `EmailHash` varchar(40) CHARACTER SET utf8 DEFAULT NULL,
  `LastAccessDate` datetime NOT NULL,
  `Location` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `Reputation` int(11) NOT NULL,
  `UpVotes` int(11) NOT NULL,
  `Views` int(11) NOT NULL,
  `WebsiteUrl` varchar(200) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.uservotes
CREATE TABLE IF NOT EXISTS `uservotes` (
  `userId` int(11) NOT NULL AUTO_INCREMENT,
  `voteId` int(11) NOT NULL,
  PRIMARY KEY (`userId`,`voteId`),
  KEY `voteId` (`voteId`),
  CONSTRAINT `uservotes_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`Id`),
  CONSTRAINT `uservotes_ibfk_2` FOREIGN KEY (`voteId`) REFERENCES `votes` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.votes
CREATE TABLE IF NOT EXISTS `votes` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `PostId` int(11) NOT NULL,
  `UserId` int(11) DEFAULT NULL,
  `BountyAmount` int(11) DEFAULT NULL,
  `VoteTypeId` int(11) NOT NULL,
  `CreationDate` datetime NOT NULL,
  `post_id` int(11) DEFAULT NULL,
  `voteType_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  KEY `PostId` (`PostId`),
  KEY `UserId` (`UserId`),
  KEY `VoteTypeId` (`VoteTypeId`),
  CONSTRAINT `votes_ibfk_1` FOREIGN KEY (`PostId`) REFERENCES `posts` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `votes_ibfk_2` FOREIGN KEY (`UserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `votes_ibfk_3` FOREIGN KEY (`VoteTypeId`) REFERENCES `votetypes` (`Id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.


# Dumping structure for table so.votetypes
CREATE TABLE IF NOT EXISTS `votetypes` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(40) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Data exporting was unselected.
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
