-- DB update 2020_09_14_00 -> 2020_09_15_00
DROP PROCEDURE IF EXISTS `updateDb`;
DELIMITER //
CREATE PROCEDURE updateDb ()
proc:BEGIN DECLARE OK VARCHAR(100) DEFAULT 'FALSE';
SELECT COUNT(*) INTO @COLEXISTS
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'version_db_world' AND COLUMN_NAME = '2020_09_14_00';
IF @COLEXISTS = 0 THEN LEAVE proc; END IF;
START TRANSACTION;
ALTER TABLE version_db_world CHANGE COLUMN 2020_09_14_00 2020_09_15_00 bit;
SELECT sql_rev INTO OK FROM version_db_world WHERE sql_rev = '1598879392104489100'; IF OK <> 'FALSE' THEN LEAVE proc; END IF;
--
-- START UPDATING QUERIES
--

INSERT INTO `version_db_world` (`sql_rev`) VALUES ('1598879392104489100');
/*
 * General: Build Update
 * Update by Knindza | <www.azerothcore.org>
 * Copyright (C) <www.shadowburn.net> & <www.lichbane.com>
*/

/* Content 3.2.0 */ 
SET @Build := 10314;

UPDATE `quest_template` SET `VerifiedBuild` = @Build WHERE `Id` IN (14112, 14108, 14107, 14105, 14104, 14102, 14101, 14136, 14140, 14141, 14142, 14143, 14144, 14145, 14152, 14096, 14092, 13889, 13903, 13904, 13905, 13914, 13915, 13916, 13917, 13926, 14090, 14080, 14077, 14076, 14074, 13927);

--
-- END UPDATING QUERIES
--
COMMIT;
END //
DELIMITER ;
CALL updateDb();
DROP PROCEDURE IF EXISTS `updateDb`;
