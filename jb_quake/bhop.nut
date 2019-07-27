function AccelerateActivator() {
	if (activator == null || activator.GetHealth() == 0) return;
	
	local velocity = activator.GetVelocity();
	local newVelocity = Vector(velocity.x+300.0, velocity.y, velocity.z);
	newVelocity.z = newVelocity.z + 10.0;
	activator.SetVelocity(newVelocity);
}