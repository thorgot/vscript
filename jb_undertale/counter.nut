//counter.nut by thorgot

::counterValue<-0

::ResetCounter<-function()
{
	counterValue<-0
	AdjustTimer(0)
}

::AdjustCounter<-function(adjustment)
{
	counterValue += adjustment
	if (counterValue < 0) counterValue = 0;
	displayValue <- (counterValue > 99 ? 99 : counterValue)
	onesDigit <- (displayValue % 10)
	tensDigit <- (displayValue / 10)
	EntFireByHandle(EntityGroup[0],"InValue",onesDigit.tostring(),0.0,null,null);
	EntFireByHandle(EntityGroup[1],"InValue",tensDigit.tostring(),0.0,null,null);
}