-- MySQL dump 10.13  Distrib 8.0.17, for macos10.14 (x86_64)
--
-- Host: cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com    Database: CLONEID
-- ------------------------------------------------------
-- Server version	5.7.22-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `CellLines`
--

DROP TABLE IF EXISTS `CellLines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CellLines` (
  `name` varchar(20) NOT NULL,
  `doublingTime_hours` int(11) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `CellSurfaceMarkers_hg19`
--

DROP TABLE IF EXISTS `CellSurfaceMarkers_hg19`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CellSurfaceMarkers_hg19` (
  `hgnc_symbol` varchar(20) NOT NULL,
  `ensembl_gene_id` varchar(20) DEFAULT NULL,
  `entrezgene` int(11) DEFAULT NULL,
  `affy_hg_u133a` varchar(20) DEFAULT NULL,
  `chr` int(11) DEFAULT NULL,
  `startpos` int(11) DEFAULT NULL,
  `endpos` int(11) DEFAULT NULL,
  `Gene` varchar(20) DEFAULT NULL,
  `Gene_synonym` varchar(160) DEFAULT NULL,
  `Ensembl` varchar(20) DEFAULT NULL,
  `Gene_description` varchar(90) DEFAULT NULL,
  `Protein_class` varchar(231) DEFAULT NULL,
  `Evidence` varchar(30) DEFAULT NULL,
  `Antibody` varchar(70) DEFAULT NULL,
  `Reliability_IH` varchar(20) DEFAULT NULL,
  `Reliability_IF` varchar(20) DEFAULT NULL,
  `Subcellular_location` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`hgnc_symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FlowCytometry`
--

DROP TABLE IF EXISTS `FlowCytometry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FlowCytometry` (
  `origin` varchar(20) NOT NULL,
  `cloneID` int(11) NOT NULL,
  `M1` varchar(20) NOT NULL,
  `M2` varchar(20) NOT NULL,
  `M3` varchar(20) NOT NULL,
  `M4` varchar(20) NOT NULL,
  `profile` varchar(50) DEFAULT NULL,
  `pValue` float DEFAULT NULL,
  `effectSize` float DEFAULT NULL,
  `testType` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`cloneID`,`M1`,`M2`,`M3`,`M4`),
  KEY `origin` (`origin`,`cloneID`),
  KEY `fk_m4` (`M1`),
  CONSTRAINT `FlowCytometry_ibfk_1` FOREIGN KEY (`origin`, `cloneID`) REFERENCES `Perspective` (`origin`, `cloneID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_m1` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m2` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m3` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m4` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Freezing`
--

DROP TABLE IF EXISTS `Freezing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Freezing` (
  `cellCount` bigint(20) NOT NULL,
  `id` varchar(20) NOT NULL,
  `freezerbox` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `what` FOREIGN KEY (`id`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Identity`
--

DROP TABLE IF EXISTS `Identity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Identity` (
  `size` float NOT NULL,
  `whichPerspective` varchar(30) DEFAULT NULL,
  `rootID` int(11) DEFAULT NULL,
  `sampleName` varchar(30) DEFAULT NULL,
  `cloneID` int(11) NOT NULL AUTO_INCREMENT,
  `profile` mediumblob,
  `profile_hash` int(11) DEFAULT NULL,
  `parent` int(11) DEFAULT NULL,
  `KaryotypePerspective` varchar(100) DEFAULT NULL,
  `GenomePerspective` varchar(100) DEFAULT NULL,
  `ExomePerspective` varchar(100) DEFAULT NULL,
  `TranscriptomePerspective` varchar(100) DEFAULT NULL,
  `coordinates` varchar(20) DEFAULT NULL,
  `profile_loci` int(11) DEFAULT NULL,
  `state` varchar(30) DEFAULT NULL,
  `alias` varchar(50) DEFAULT NULL,
  `hasChildren` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`cloneID`),
  KEY `profile_loci` (`profile_loci`),
  CONSTRAINT `identity_ibfk_1` FOREIGN KEY (`profile_loci`) REFERENCES `Loci` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2249 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Loci`
--

DROP TABLE IF EXISTS `Loci`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Loci` (
  `content` mediumblob,
  `hash` int(11) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`)
) ENGINE=InnoDB AUTO_INCREMENT=1313542 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Passaging`
--

DROP TABLE IF EXISTS `Passaging`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Passaging` (
  `id` varchar(20) NOT NULL,
  `cellLine` varchar(20) DEFAULT NULL,
  `event` enum('seeding','harvest') DEFAULT NULL,
  `passaged_from_id1` varchar(20) DEFAULT NULL,
  `passaged_from_id2` varchar(20) DEFAULT NULL,
  `dish` enum('T75_flask','T25_flask','P100mm_plate','P60mm_plate','P35mm_plate','6well_plate','12well_plate','24well_plate','96well_plate','HYPERflask') DEFAULT NULL,
  `growthType` varchar(30) DEFAULT NULL,
  `passage` int(11) NOT NULL,
  `cellCount` bigint(20) DEFAULT NULL,
  `date` timestamp NOT NULL,
  `address` varchar(250) DEFAULT 'CCSR Stanford',
  `media` varchar(250) DEFAULT NULL,
  `mediaVolume` float DEFAULT NULL,
  `stressExposure` varchar(250) DEFAULT NULL,
  `comment` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_harvest1` (`passaged_from_id1`),
  KEY `fk_harvest2` (`passaged_from_id2`),
  CONSTRAINT `fk_harvest1` FOREIGN KEY (`passaged_from_id1`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_harvest2` FOREIGN KEY (`passaged_from_id2`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`noemi`@`%`*/ /*!50003 TRIGGER passage_increment BEFORE INSERT ON Passaging
FOR EACH ROW BEGIN
  IF NEW.passage=0 THEN
    IF NEW.event='seeding' THEN
      SET NEW.passage = (SELECT passage +1 FROM Passaging WHERE id = NEW.passaged_from_id1);
    ELSE
      SET NEW.passage = (SELECT passage FROM Passaging WHERE id = NEW.passaged_from_id1);
    END IF;  
  END IF;
  IF NEW.cellLine IS NULL THEN
    SET NEW.cellLine = (SELECT cellLine FROM Passaging WHERE id = NEW.passaged_from_id1);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Perspective`
--

DROP TABLE IF EXISTS `Perspective`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Perspective` (
  `whichPerspective` varchar(30) DEFAULT NULL,
  `size` float DEFAULT NULL,
  `parent` int(11) DEFAULT NULL,
  `profile` mediumblob,
  `profile_hash` int(11) DEFAULT NULL,
  `origin` varchar(20) DEFAULT NULL,
  `sampleName` varchar(20) DEFAULT NULL,
  `coordinates` varchar(20) DEFAULT NULL,
  `rootID` int(11) DEFAULT NULL,
  `cloneID` int(11) NOT NULL AUTO_INCREMENT,
  `profile_loci` int(11) DEFAULT NULL,
  `state` varchar(30) DEFAULT NULL,
  `alias` varchar(50) DEFAULT NULL,
  `hasChildren` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`cloneID`),
  KEY `profile_loci` (`profile_loci`),
  KEY `FK_rootID` (`origin`),
  CONSTRAINT `FK_rootID` FOREIGN KEY (`origin`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `perspective_ibfk_1` FOREIGN KEY (`profile_loci`) REFERENCES `Loci` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=133877 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-02-20 14:44:24
