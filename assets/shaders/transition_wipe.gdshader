shader_type canvas_item;

// Range 0.0 to 1.0
// 0.0 = Fully Covered (Showing capture)
// 1.0 = Fully Revealed (Showing new game state)
uniform float progress : hint_range(0.0, 1.0);

void fragment() {
	// Diagonal Gradient: Bottom-Left (0,1) to Top-Right (1,0)
	// value increases from 0 (BL) to 2 (TR)
	float val = UV.x + (1.0 - UV.y);
	
	// We want to wipe from BL to TR.
	// So pixels with LOW val should become transparent first.
	// Pixels with HIGH val should stay opaque longer.
	
	// 'Threshold' determines the boundary between Transparent and Opaque.
	// val < threshold -> Transparent
	// val > threshold -> Opaque
	
	// Mapping progress to threshold:
	// Prog 0: All pixels should be Opaque (val > threshold).
	//         Since val >= 0, threshold must be < 0. (e.g. -0.5)
	// Prog 1: All pixels should be Transparent (val < threshold).
	//         Since val <= 2, threshold must be > 2. (e.g. 2.5)
	
	float feather = 0.5;
	float threshold = progress * 3.0 - 0.5; 
	
	// smoothstep(edge0, edge1, x)
	// 0 if x < edge0
	// 1 if x > edge1
	float alpha = smoothstep(threshold, threshold + feather, val);
	
	COLOR.a = alpha;
}
