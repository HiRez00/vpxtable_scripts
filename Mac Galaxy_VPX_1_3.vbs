'############################################################################################
'############################################################################################
'#######                                                                             ########
'#######          Mac's Galaxy                                                       ########
'#######          (M.A.C. 1986)                                                      ########
'#######                                                                             ########
'############################################################################################
'############################################################################################
'
' Version 1.1
' - new configuration item ForceNoB2S
' - changed SolGameOn to #10
' - added DT x10 lights for score rollovers
'
' Version 1.2
' - added flippers rotatetostart on GameOver
' - adjusted left Slingshot trigger (found by Mustang1961)
'
' Version 1.3
' - adjusted friction values (found by JPSalas)


Option Explicit
 
On Error Resume Next
ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the controller.vbs in order to run this table, available in the vp10 package"
On Error Goto 0

'-----------------------------------
'------  Global Cofigurations ------
'-----------------------------------
Const FreePlay=True			'set table to Free Play	
Const DimGI=10				'set to dim or brighten GI lights (base value is 10)
Const ForceNoB2S=False		'set to True to skip the B2S calls - B2S errors lead to bad solenoid and lamp init sequences




Const cgamename = "macgalxy"
Const UseSolenoids=1,UseLamps=1,SSolenoidOn="SolOn",SSolenoidOff="SolOff",SFlipperOn="FlipperUp",SFlipperOff="FlipperDown",SCoin="coin3"

if ForceNoB2S Then
	LoadVPMALT "01560000","mac.VBS",3.2
else
	LoadVPM "01560000","mac.VBS",3.2
end If


'-----------------------------------
'------  Solenoid Assignment  ------
'-----------------------------------

SolCallback(1)="bsTrough.SolOut"				
SolCallback(4)="Sol4"							'Drop Target Bank
SolCallback(5)="bsRightHole.SolOut"			
SolCallback(10)="Sol10"							'GameOn
SolCallback(18)="vpmSolSound ""knocker"","

Sub Sol4(enabled)
	if enabled then
		DropTargetBank.DropSol_On
	end if
End Sub

Sub Sol10(enabled)
	Flipperactive = enabled
	if not enabled Then
		LeftFlipper.rotatetostart
		RightFlipper.rotatetostart
	end If
End Sub

'--------------------------
'------  Table Init  ------
'--------------------------
Dim bsTrough,bsRightHole,DropTargetBank,cRightCaptive,Flipperactive,obj
Dim DesktopMode: DesktopMode = MacsGalaxy.ShowDT

If DesktopMode = True Then 'Show Desktop components
	Ramp16.visible=1
	Ramp15.visible=1
	SideWood.visible=1
Else
	Ramp16.visible=0
	Ramp15.visible=0
	SideWood.visible=0
	for each obj in DTLights
		obj.visible = False
	Next
End if

for each obj in GI
	obj.intensity = DimGI
next

Sub MacsGalaxy_Init
	vpminit me
    vpmMapLights AllLights
	
    Controller.GameName=cGameName
    Controller.SplashInfoLine="Mac's Galaxy" & vbNewLine & "created by mfuegemann"
    Controller.HandleKeyboard=False
    Controller.ShowTitle=0
    Controller.ShowFrame=0
    Controller.ShowDMDOnly=1
	'Controller.Hidden = 1			'enable to hide DMD if You use a B2S backglass

'    'DMD position for 3 Monitor Setup
'    'Controller.Games(cGameName).Settings.Value("dmd_pos_x")=3850		'set this to 0 if You cannot find the DMD
'    'Controller.Games(cGameName).Settings.Value("dmd_pos_y")=300		'set this to 0 if You cannot find the DMD
'    'Controller.Games(cGameName).Settings.Value("dmd_width")=505
'    'Controller.Games(cGameName).Settings.Value("dmd_height")=155
'    'Controller.Games(cGameName).Settings.Value("rol")=0				
'
'	'Controller.Games(cGameName).Settings.Value("ddraw") = 0             'set to 0 if You have problems with DMD showing or table stutter
		   
    Controller.HandleMechanics=0

'	vpmTimer.AddTimer 2000, "Controller.SolMask(0)=&Hffffffff'" 'ignore all solenoids - then add the Timer to renable all the solenoids after 2 seconds

    Controller.Run 
    If Err Then MsgBox Err.Description
    On Error Goto 0

    PinMAMETimer.Interval=PinMAMEInterval
	PinMAMETimer.Enabled = true

    vpmNudge.TiltSwitch=4
    vpmNudge.Sensitivity=5
	vpmNudge.TiltObj = Array(LeftFlipper,RightFlipper,Bumper1,Bumper2,Bumper3) 

    Set bsTrough=New cvpmBallStack
        bsTrough.InitSw 0,37,0,0,0,0,0,0 		'0.1 = Switch 0
        bsTrough.InitKick BallRelease,90,5
        bsTrough.InitExitSnd SoundFX("BallRel",DOFContactors),SoundFX("Solenoid",DOFContactors)
        bsTrough.Balls=1

	set DropTargetBank = new cvpmDropTarget
		DropTargetBank.InitDrop Array(DT1,DT2,DT3,DT4), Array(25,26,27,31)
		DropTargetBank.InitSnd SoundFX("Targetdrop1",DOFContactors),SoundFX("TargetBankreset1",DOFContactors)
		DropTargetBank.CreateEvents "DropTargetBank"

	Set bsRightHole = New cvpmBallStack
		bsRightHole.InitExitSnd SoundFX("Popper",DOFContactors),SoundFX("Solenoid",DOFContactors)
		bsRightHole.initsaucer RHole,13,130,10

	Set cRightCaptive=New cvpmCaptiveBall
		cRightCaptive.InitCaptive RightCaptiveTrigger,RightCaptiveWall,RightCaptiveKicker,15
		cRightCaptive.Start
		cRightCaptive.ForceTrans = 0.6
		cRightCaptive.MinForce = 3.5
		cRightCaptive.CreateEvents "cRightCaptive"
End Sub

Sub MacsGalaxy_Exit()
	Controller.Pause = False
	Controller.Stop
End Sub

'------------------------------
'------  Trough Handler  ------
'------------------------------
Sub Drain_Hit()
	bsTrough.AddBall Me
	playsound "Drain5"	
End Sub


'------------------------------
'------  Switch Handler  ------
'------------------------------
Sub RHole_Hit:bsRightHole.addball 0:End Sub

Sub Bumper1_Hit:vpmTimer.PulseSw 15:PlaySound SoundFX("Jet2",DOFContactors),0,1,0,0.05:End Sub
Sub Bumper2_Hit:vpmTimer.PulseSw 17:PlaySound SoundFX("Jet1",DOFContactors),0,1,-0.1,0.05:End Sub
Sub Bumper3_Hit:vpmTimer.PulseSw 18:PlaySound SoundFX("Jet1",DOFContactors),0,1,0.1,0.05:End Sub

sub LOutlane_hit:Controller.Switch(30)=1:End Sub
sub LOutlane_unhit:Controller.Switch(30)=0:End Sub
sub LInlane_hit:Controller.Switch(23)=1:End Sub
sub LInlane_unhit:Controller.Switch(23)=0:End Sub

sub ROutlane_hit:Controller.Switch(36)=1:End Sub
sub ROutlane_unhit:Controller.Switch(36)=0:End Sub
sub RInlane_hit:Controller.Switch(35)=1:End Sub
sub RInlane_unhit:Controller.Switch(35)=0:End Sub

sub TopRollover_Left_hit:Controller.Switch(9)=1:End Sub
sub TopRollover_Left_unhit:Controller.Switch(9)=0:End Sub
sub TopRollover_Middle_hit:Controller.Switch(10)=1:End Sub
sub TopRollover_Middle_unhit:Controller.Switch(10)=0:End Sub
sub TopRollover_Right_hit:Controller.Switch(11)=1:End Sub
sub TopRollover_Right_unhit:Controller.Switch(11)=0:End Sub

sub LeftTarget_hit:vpmTimer.PulseSw 12:End Sub
sub CenterTarget_hit:vpmTimer.PulseSw 19:End Sub
sub RightCaptive_hit:vpmTimer.PulseSw 14:End Sub

sub RPassage_hit:Controller.Switch(29)=1:End Sub
sub RPassage_unhit:Controller.Switch(29)=0:End Sub

Sub Rubber20_Hit:vpmTimer.PulseSw 20:End Sub
Sub Rubber21_Hit:vpmTimer.PulseSw 21:End Sub
Sub Rubber22_Hit:vpmTimer.PulseSw 22:End Sub
Sub Rubber28_Hit:vpmTimer.PulseSw 28:End Sub

Sub LaunchTrigger_Hit
	if activeball.vely < 6 Then
		Playsound "Launch",0,0.6,0.8
	end if	
End Sub

'-------------------------------
'------  Keybord Handler  ------
'-------------------------------

Sub MacsGalaxy_KeyDown(ByVal keycode)
	If keycode = PlungerKey Then
		Plunger.PullBack
		Playsound "PlungerPull",0,1,0.8
	End If
	if Flipperactive then
		If keycode = LeftFlipperKey Then
			LeftFlipper.RotatetoEnd
			PlaySound SoundFX("FlipperUp_Akiles",DOFContactors),0,1,-0.1,0.25
		End If
		If keycode = RightFlipperKey Then
			RightFlipper.RotatetoEnd
			PlaySound SoundFX("FlipperUp_Akiles",DOFContactors),0,1,0.1,0.25
		End If
	end if
	if keycode = StartGameKey and FreePlay then
		vpmTimer.PulseSw 3
	end if
	If vpmKeyDown(KeyCode) Then Exit Sub
End Sub

Sub MacsGalaxy_KeyUp(ByVal keycode)
	If keycode = PlungerKey Then
		Plunger.Fire
		Playsound "Plunger",0,1,0.8
	End If
	if Flipperactive then
		If keycode = LeftFlipperKey Then
			LeftFlipper.RotatetoStart
			PlaySound SoundFX("FlipperDown_Akiles",DOFContactors),0,1,-0.1,0.25
		End If
		If keycode = RightFlipperKey Then
			RightFlipper.RotatetoStart
			PlaySound SoundFX("FlipperDown_Akiles",DOFContactors),0,1,0.1,0.25
		End If
	end if

	If vpmKeyUp(KeyCode) Then Exit Sub
End Sub


'-----------------------------------
' Flipper Primitives
'-----------------------------------
sub FlipperTimer_Timer()
	DT4Wall.isdropped = DT4.isdropped
end sub


'**********Sling Shot Animations
' Rstep and Lstep  are the variables that increment the animation
'****************
Dim RStep, Lstep

Sub RightSlingShot_Slingshot
	vpmtimer.pulsesw 33
    PlaySound SoundFX("rsling",DOFContactors), 0, 1, 0.05, 0.05
    RSling.Visible = 0
    RSling1.Visible = 1
    sling1.TransZ = -20
    RStep = 0
    RightSlingShot.TimerEnabled = 1
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 3:RSLing1.Visible = 0:RSLing2.Visible = 1:sling1.TransZ = -10
        Case 4:RSLing2.Visible = 0:RSLing.Visible = 1:sling1.TransZ = 0:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

Sub LeftSlingShot_Slingshot
	vpmtimer.pulsesw 34
    PlaySound SoundFX("lsling",DOFContactors),0,1,-0.05,0.05
    LSling.Visible = 0
    LSling1.Visible = 1
    sling2.TransZ = -20
    LStep = 0
    LeftSlingShot.TimerEnabled = 1
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 3:LSLing1.Visible = 0:LSLing2.Visible = 1:sling2.TransZ = -10
        Case 4:LSLing2.Visible = 0:LSLing.Visible = 1:sling2.TransZ = 0:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub


'-----------------------------------
' DIP Switch Menu
'-----------------------------------

Sub editDips
	Dim vpmDips:Set vpmDips=New cvpmDips
	With vpmDips
		.AddForm 400,200,"MAC's Galaxy - DIP switches"
		.AddFrame 0,0,110,"Balls per game",&H00000001,Array("5 Balls",0,"3 Balls",&H00000001)'dip 1 (A)
		.AddFrame 0,50,110,"Coin Chute settings",&H00000006,Array("1/2 - 3",0,"1/2 - 4",&H00000002,"1 - 5",&H00000006)'dip 2&3 (A)
		.AddChk 0,115,110,Array("Enable Music",&H00000020)'dip 6 (A)
		.AddLabel 0,140,280,20,"After hitting OK, press F3 to reset game with new settings."
		.ViewDips
	End With
End Sub
Set vpmShowDips=GetRef("editDips")




' *********************************************************************
'                      Supporting Ball & Sound Functions
' *********************************************************************

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 300)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / MacsGalaxy.width-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10) )
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = INT(SQR((ball.VelX ^2) + (ball.VelY ^2) ) )
End Function

'*****************************************
'      JP's VP10 Rolling Sounds
'*****************************************

Const tnob = 2 ' total number of balls
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingTimer_Timer()
    Dim BOT, b
    BOT = GetBalls

	' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
    Next

	' exit the sub if no balls on the table
    If UBound(BOT) = -1 Then Exit Sub

	' play the rolling sound for each ball
    For b = 0 to UBound(BOT)
        If BallVel(BOT(b) ) > 1 AND BOT(b).z < 30 Then
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, Vol(BOT(b) ), Pan(BOT(b) ), 0, Pitch(BOT(b) ), 1, 0
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If
    Next
End Sub

'**********************
' Ball Collision Sound
'**********************

Sub OnBallBallCollision(ball1, ball2, velocity)
	PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0
End Sub



'************************************
' What you need to add to your table
'************************************

' a timer called RollingTimer. With a fast interval, like 10
' one collision sound, in this script is called fx_collide
' as many sound files as max number of balls, with names ending with 0, 1, 2, 3, etc
' for ex. as used in this script: fx_ballrolling0, fx_ballrolling1, fx_ballrolling2, fx_ballrolling3, etc


'******************************************
' Explanation of the rolling sound routine
'******************************************

' sounds are played based on the ball speed and position

' the routine checks first for deleted balls and stops the rolling sound.

' The For loop goes through all the balls on the table and checks for the ball speed and 
' if the ball is on the table (height lower than 30) then then it plays the sound
' otherwise the sound is stopped, like when the ball has stopped or is on a ramp or flying.

' The sound is played using the VOL, PAN and PITCH functions, so the volume and pitch of the sound
' will change according to the ball speed, and the PAN function will change the stereo position according
' to the position of the ball on the table.


'**************************************
' Explanation of the collision routine
'**************************************

' The collision is built in VP.
' You only need to add a Sub OnBallBallCollision(ball1, ball2, velocity) and when two balls collide they 
' will call this routine. What you add in the sub is up to you. As an example is a simple Playsound with volume and paning
' depending of the speed of the collision.


Sub Pins_Hit (idx)
	PlaySound "pinhit_low", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0
End Sub

Sub Targets_Hit (idx)
	PlaySound SoundFX("target",DOFTargets), 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0
End Sub

Sub Metals_Thin_Hit (idx)
	PlaySound "metalhit_thin", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
End Sub

Sub Metals_Medium_Hit (idx)
	PlaySound "metalhit_medium", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
End Sub

Sub Metals2_Hit (idx)
	PlaySound "metalhit2", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
End Sub

Sub Gates_Hit (idx)
	PlaySound "gate", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
End Sub

Sub Spinner_Spin
	PlaySound "fx_spinner",0,.25,0,0.25
End Sub

Sub Rubbers_Hit(idx)
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 20 then 
		PlaySound "fx_rubber2", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
	End if
	If finalspeed >= 6 AND finalspeed <= 20 then
 		RandomSoundRubber()
 	End If
End Sub

Sub Posts_Hit(idx)
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 16 then 
		PlaySound "fx_rubber2", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
	End if
	If finalspeed >= 6 AND finalspeed <= 16 then
 		RandomSoundRubber()
 	End If
End Sub

Sub RandomSoundRubber()
	Select Case Int(Rnd*3)+1
		Case 1 : PlaySound "rubber_hit_1", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
		Case 2 : PlaySound "rubber_hit_2", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
		Case 3 : PlaySound "rubber_hit_3", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
	End Select
End Sub

Sub LeftFlipper_Collide(parm)
 	RandomSoundFlipper()
End Sub

Sub RightFlipper_Collide(parm)
 	RandomSoundFlipper()
End Sub

Sub RandomSoundFlipper()
	Select Case Int(Rnd*3)+1
		Case 1 : PlaySound "flip_hit_1", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
		Case 2 : PlaySound "flip_hit_2", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
		Case 3 : PlaySound "flip_hit_3", 0, Vol(ActiveBall), Pan(ActiveBall), 0, Pitch(ActiveBall), 1, 0
	End Select
End Sub

