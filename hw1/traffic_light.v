module traffic_light (
    input  clk,
    input  rst,
    input  pass,
    output R,
    output G,
    output Y
);

reg [3:0] state;
reg [31:0] cycle;
reg [31:0] top;
reg r, g, y;

assign R = r;
assign G = g;
assign Y = y;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		cycle = 1;
		state = 0;
		top = 1024;
		g = 1;
		r = 0;
		y = 0;
	end
	else if (pass && state != 0) begin
		cycle = 1;
		top = 1024;
		state = 0;
		g = 1;
		r = 0;
		y = 0;
	end	
	else if (cycle == top) begin
		cycle = 1;
		state = (state + 1) % 7;
		case (state)
			0: begin
				top = 1024;
				g = 1;
				r = 0;
				y = 0;	
			end
			
			1: begin
				top = 128;
				g = 0;
				r = 0;
				y = 0;
			end
			2: begin
				top = 128;
				g = 1;
				r = 0;
				y = 0;
			end
			3: begin
				top = 128;
				g = 0;
				r = 0;
				y = 0;
			end
			4: begin
				top = 128;
				g = 1;
				r = 0;
				y = 0;
			end
			5: begin
				top = 512;
				g = 0;
				r = 0;
				y = 1;
			end
			6: begin
				top = 1024;
				g = 0;
				r = 1;
				y = 0;
			end
		endcase
	end
	else begin
		cycle = cycle + 1;
	end
end


endmodule
