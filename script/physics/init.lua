local p = physicsModule;

-- Gravity used by all physics scenes
p:setGravity(engine.base.mathbase.GameDirections.sceneUpDirection * -9.81);


engine.component.AbstractPhysicsComponent.DominanceGroup.rename(
{
	DominanceGroupStatic = 0,
	DominanceGroupMagneticShield = 1,
	DominanceGroupDynamic = 15,
	DominanceGroupRagdoll = 16,
	DominanceGroupModelParticle = 17,
	DominanceGroupFoliage = 18,
});

-- NOTE: collision group number 31 is reserved for disabled collisions! 
-- (Never use that for any other purpose.)
engine.component.AbstractPhysicsComponent.CollisionGroup.rename(
{
	CollisionGroupDynamic = 0,
	CollisionGroupStatic = 1,
	CollisionGroupNoCollision = 2,
	CollisionGroupCharacter = 3,
	CollisionGroupPlayerCharacter = 4,
	CollisionGroupRagdoll = 5,
	CollisionGroupItem = 6,
	CollisionGroupContainment = 7,	
	CollisionGroupDynamicNoStatic = 8,
	CollisionGroupDynamicNoCharacter = 9,
	CollisionGroupDynamicNoNavmesh = 10,
	CollisionGroupSpecialObject = 11,
	CollisionGroupCameraObstacle = 12,
	CollisionGroupNavMeshHole = 13,
	CollisionGroupCharacterNoCharColl = 14,
	CollisionGroupCameraBoundary = 15,
	CollisionGroupSpikeCollision = 16,
	CollisionGroupModelParticle = 17,
	CollisionGroupHideOut = 18,
	CollisionGroupShieldOnly = 19,
	CollisionGroupFiretrough = 20,
	CollisionGroupStopMe = 21,	
	CollisionGroupStopMeCharacter = 22,
	CollisionGroupEnvironment = 23,	
	CollisionGroupSpecialObjectOnly = 24,
	CollisionGroupPlayerCharacterOnly = 25,
	CollisionGroupFiretroughDynamic = 26,
	CollisionGroupPlayerCharacterAndDynamic = 27,
	CollisionGroupModelParticleOnly = 28,
	CollisionGroupStopMeCharacterStaticOnly = 29,
	CollisionGroupDynamicWithHoles = 30
});

local p = physicsModule
local sgcr = p.setGroupContactReports
local sgc = p.setGroupCollisions
local apc = engine.component.AbstractPhysicsComponent

-- 0 for no contact reports, 1 for continuous contact reports, 2 for contact reports on start of contact only
--
--                                                       D  S  N  C  P  R  I  C  D  D  D  S  C  N  C  D  S  M  H  S  F  S  S  E  S  P  F  P  M  S  D
--                                                       y  t  o  h  l  a  t  o  y  y  y  p  a  a  h  a  p  o  i  h  i  t  t  n  p  l  i  l  o  t  y
--                                                       n  a  C  a  C  g  e  n  n  n  n  e  m  v  a  m  i  d  d  i  r  o  o  v  O  C  r  C  P  o  n
--                                                       a  t  o  r  h  d  m  t  N  N  N  c  O  m  r  B  k  e  e  e  e  p  p  r  b  h  T  &  a  p  W
--                                                       m  i  l  a  a  o  .  a  o  o  o  O  b  e  N  o  e  l  O  l  T  M  M  n  O  O  h  D  O  M  H
--                                                       i  c  l  c  r  l  .  i  S  C  N  b  s  H  o  u  C  P  u  d  h  e  e  m  n  n  D  y  n  e  o
--                                                       c  .  .  .  .  .  .  n  t  h  m  j  t  o  C  n  o  a  t  O  r  .  C  t  l  l  y  n  l  S  l
--                                                       .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  o  e
sgcr(p, apc.CollisionGroupDynamic                     ,{ 1, 1, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1});
sgcr(p, apc.CollisionGroupStatic                      ,{ 1, 1, 0, 1, 1, 2, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupNoCollision                 ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupCharacter                   ,{ 1, 1, 0, 1, 1, 2, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupPlayerCharacter             ,{ 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1});
sgcr(p, apc.CollisionGroupRagdoll                     ,{ 2, 2, 0, 2, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 2, 2, 0, 0, 2, 0, 0, 0, 2});
sgcr(p, apc.CollisionGroupItem                        ,{ 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupContainment                 ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupDynamicNoStatic             ,{ 1, 0, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupDynamicNoCharacter          ,{ 1, 1, 0, 0, 0, 2, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupDynamicNoNavmesh            ,{ 1, 1, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1});
sgcr(p, apc.CollisionGroupSpecialObject               ,{ 1, 1, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1});
sgcr(p, apc.CollisionGroupCameraObstacle              ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupNavMeshHole                 ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupCharacterNoCharColl         ,{ 1, 1, 0, 0, 1, 2, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupCameraBoundary              ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupSpikeCollision              ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupModelParticle               ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0});
sgcr(p, apc.CollisionGroupHideOut                     ,{ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupShieldOnly                  ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupFiretrough                  ,{ 1, 0, 0, 1, 1, 2, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupStopMe                      ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0});
sgcr(p, apc.CollisionGroupStopMeCharacter             ,{ 1, 1, 0, 1, 1, 2, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupEnvironment                 ,{ 1, 1, 0, 1, 1, 2, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupSpecialObjectOnly           ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupPlayerCharacterOnly         ,{ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupFiretroughDynamic           ,{ 1, 1, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgcr(p, apc.CollisionGroupPlayerCharacterAndDynamic   ,{ 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupModelParticleOnly           ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupStopMeCharacterStaticOnly   ,{ 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0});
sgcr(p, apc.CollisionGroupDynamicWithHoles            ,{ 1, 1, 0, 1, 1, 2, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});

-- 0 for no collision, 1 for collision
--
--                                                    D  S  N  C  P  R  I  C  D  D  D  S  C  N  C  C  S  M  H  S  F  S  S  E  S  P  F  P  M  S  D
--                                                    y  t  o  h  l  a  t  o  y  y  y  p  a  a  h  a  p  o  i  h  i  t  t  n  p  l  i  l  o  t  y
--                                                    n  a  C  a  C  g  e  n  n  n  n  e  m  v  a  m  i  d  d  i  r  o  o  v  O  C  r  c  P  o  n
--                                                    a  t  o  r  h  d  m  t  N  N  N  c  O  M  r  B  k  e  e  e  e  p  p  r  b  h  T  &  a  p  W
--                                                    m  i  l  a  a  o  .  a  o  o  o  O  b  e  N  o  e  l  O  l  T  M  M  m  O  O  h  D  O  M  H
--                                                    i  c  l  c  r  l  .  i  S  C  N  b  s  H  o  u  C  P  u  d  h  e  e  n  n  n  D  y  n  e  o
--                                                    c  .  .  .  .  .  .  n  t  h  m  j  t  o  C  n  o  a  t  O  r  .  C  t  l  l  y  n  l  S  l
--                                                    .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  o  e
sgc(p, apc.CollisionGroupDynamic                   ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1});
sgc(p, apc.CollisionGroupStatic                    ,{ 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1});
sgc(p, apc.CollisionGroupNoCollision               ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupCharacter                 ,{ 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupPlayerCharacter           ,{ 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1});
sgc(p, apc.CollisionGroupRagdoll                   ,{ 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupItem                      ,{ 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupContainment               ,{ 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupDynamicNoStatic           ,{ 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupDynamicNoCharacter        ,{ 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupDynamicNoNavmesh          ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1});
sgc(p, apc.CollisionGroupSpecialObject             ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1});
sgc(p, apc.CollisionGroupCameraObstacle            ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupNavMeshHole               ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupCharacterNoCharColl       ,{ 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupCameraBoundary            ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupSpikeCollision            ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupModelParticle             ,{ 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1});
sgc(p, apc.CollisionGroupHideOut                   ,{ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupShieldOnly                ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupFiretrough                ,{ 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupStopMe                    ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0});
sgc(p, apc.CollisionGroupStopMeCharacter           ,{ 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupEnvironment               ,{ 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1});
sgc(p, apc.CollisionGroupSpecialObjectOnly         ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupPlayerCharacterOnly       ,{ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupFiretroughDynamic         ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});
sgc(p, apc.CollisionGroupPlayerCharacterAndDynamic ,{ 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupModelParticleOnly         ,{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupStopMeCharacterStaticOnly ,{ 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0});
sgc(p, apc.CollisionGroupDynamicWithHoles          ,{ 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1});

local masses = 
{
	-- min should have num 0
	{ name = "MassMin", num = 0, numericMass = 0.25 },
	
	{ name = "MassVeryLightLevel1", num = 1, numericMass = 0.25 },
	{ name = "MassVeryLightLevel2", num = 2, numericMass = 0.5 },
	{ name = "MassVeryLightLevel3", num = 3, numericMass = 1.0 },
	{ name = "MassLightLevel1", num = 4, numericMass = 1.5 },
	{ name = "MassLightLevel2", num = 5, numericMass = 2.0 },
	{ name = "MassLightLevel3", num = 6, numericMass = 2.5 },
	{ name = "MassMediumLevel1", num = 7, numericMass = 3.0 },
	{ name = "MassMediumLevel2", num = 8, numericMass = 4.0 },
	{ name = "MassMediumLevel3", num = 9, numericMass = 5.0 },
	{ name = "MassHeavyLevel1", num = 10, numericMass = 6.0 },
	{ name = "MassHeavyLevel2", num = 11, numericMass = 7.0 },
	{ name = "MassHeavyLevel3", num = 12, numericMass = 8.0 },
	{ name = "MassMassiveLevel1", num = 13, numericMass = 10.0 },
	{ name = "MassMassiveLevel2", num = 14, numericMass = 15.0 },
	{ name = "MassMassiveLevel3", num = 15, numericMass = 20.0 },
		
	-- max should have num 31
	{ name = "MassMax", num = 31, numericMass = 20.0 }
}

for i,v in ipairs(masses) do physicsModule.setMass(v) end

-- HACK: turned out the current Lua integration won't bend to this easily... (or at least I have no idea how to do it)
-- so this re-factored solution is doing crappy stuff here
massesRenameTable = { MassNotSet = 0 } for i,v in ipairs(masses) do massesRenameTable[v.name] = v.num end
engine.component.AbstractPhysicsComponent.Mass.rename(massesRenameTable)
