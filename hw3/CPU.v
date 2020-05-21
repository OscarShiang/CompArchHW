// Please include verilog file if you write module in other file
module CPU(
    input             clk,
    input             rst,
    input      [31:0] data_out,
    input      [31:0] instr_out,
    output reg        instr_read,
    output reg        data_read,
    output reg [31:0] instr_addr,
    output reg [31:0] data_addr,
    output reg [3:0]  data_write,
    output reg [31:0] data_in
);

parameter read_instr = 0, process = 1, memory = 2, update = 3;

reg [31:0] pc;
reg [31:0] regis[31:0];
reg [1:0] state;
reg set_pc;

reg [6:0] funct7;
reg [2:0] funct3;
reg [4:0] rs2, rs1, rd;
reg [6:0] opcode;

reg [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
reg [4:0] shamt;
reg flag;

reg [31:0] tmp;

always @(posedge clk) begin
	if (rst) begin
		// reset
		pc = 0;
		instr_read = 1;
		instr_addr = 0;

		data_read = 0;
		data_addr = 0;
		data_write = 0;

		state = read_instr;
		set_pc = 0;

		flag = 0;
		data_addr = 0;
		data_in = 0;

		regis[0] = 0;
	end
	else begin
		case (state)
			read_instr: begin
				data_write = 0;
				data_read = 0;

				instr_addr = pc;
				regis[0] = 0;

				// instr_addr = pc;
				imm_i = {{20{instr_out[31]}}, instr_out[31:20]};
				imm_s = {{20{instr_out[31]}}, instr_out[31:25], instr_out[11:7]};
				imm_b = {{19{instr_out[31]}}, instr_out[31], instr_out[7], instr_out[30:25], instr_out[11:8], 1'b0};
				imm_u = {instr_out[31:12], 12'd0};
				imm_j = {{11{instr_out[31]}}, instr_out[31], instr_out[19:12], instr_out[20], instr_out[30:21], 1'b0};

				shamt = instr_out[24:20];
	
				{funct7, rs2, rs1, funct3, rd, opcode} = instr_out;	
				if (!instr_read)
					state = process;
				else begin
					instr_read = 0;
				end
					
			end

			process: begin
				regis[0] = 0;
				set_pc = 0;

				case (opcode)
					7'b0110011: begin
						case ({funct7, funct3})
							10'b0000000000: regis[rd] = regis[rs1] + regis[rs2];
							10'b0100000000: regis[rd] = regis[rs1] - regis[rs2];
							10'b0000000001: regis[rd] = $unsigned(regis[rs1]) << regis[rs2][4:0];
							10'b0000000010: regis[rd] = ($signed(regis[rs1]) < $signed(regis[rs2])) ? 1 : 0;
							10'b0000000011: regis[rd] = ($unsigned(regis[rs1]) < $unsigned(regis[rs2])) ? 1 : 0;
							10'b0000000100: regis[rd] = regis[rs1] ^ regis[rs2];
							10'b0000000101: regis[rd] = $unsigned(regis[rs1]) >> regis[rs2][4:0];
							10'b0100000101: regis[rd] = $signed(regis[rs1]) >>> regis[rs2][4:0];
							10'b0000000110: regis[rd] = regis[rs1] | regis[rs2];
							10'b0000000111: regis[rd] = regis[rs1] & regis[rs2];
						endcase

						state = read_instr;
					end 

					7'b0000011: begin	
						data_addr = regis[rs1] + imm_i;
						data_read = 1;

						state = memory;
					end

					7'b0010011: begin
						case (funct3)
							3'b000: regis[rd] = regis[rs1] + imm_i;
							3'b010: regis[rd] = ($signed(regis[rs1]) < $signed(imm_i)) ? 1 : 0;
							3'b011: regis[rd] = ($unsigned(regis[rs1]) < $unsigned(imm_i)) ? 1 : 0;
							3'b100: regis[rd] = regis[rs1] ^ imm_i;
							3'b110: regis[rd] = regis[rs1] | imm_i;
							3'b111: regis[rd] = regis[rs1] & imm_i;
							3'b001: regis[rd] = $unsigned(regis[rs1]) << shamt;
							3'b101: begin
								if (imm_i[10]) 
									regis[rd] = $signed(regis[rs1]) >>> shamt;
								else
									regis[rd] = $unsigned(regis[rs1]) >> shamt;
							end
						endcase
						state = read_instr;
					end

					7'b1100111: begin
						tmp = regis[rs1];
						regis[rd] = pc + 4;
						pc = imm_i + tmp;
						pc[0] = 0;
						set_pc = 1;
						state = read_instr;
					end

					7'b0100011: begin
						data_addr = regis[rs1] + imm_s;
						
						case (funct3)
							3'b010: begin
								data_in = regis[rs2];
								data_write = 15;
							end 
							3'b000: begin
								case (data_addr[1:0])
									2'b00: begin
										data_in = {24'd0, regis[rs2][7:0]};
										data_write = 4'b0001;
									end 
									2'b01: begin
										data_in = {16'd0, regis[rs2][7:0], 8'd0};
										data_write = 4'b0010;
									end
									2'b10: begin
										data_in = {8'd0, regis[rs2][7:0], 16'd0};
										data_write = 4'b0100;
									end 
									2'b11: begin
										data_in = {regis[rs2][7:0], 24'd0};
										data_write = 4'b1000;
									end
								endcase	
							end
							3'b001: begin
								case (data_addr[1:0])
									2'b00: begin
										data_in = {16'd0, regis[rs2][15:0]};
										data_write = 4'b0011;
									end
									2'b01: begin
										data_in = {8'd0, regis[rs2][15:0], 8'd0};
										data_write = 4'b0110;
									end
									2'b10: begin
										data_in = {regis[rs2][15:0], 16'd0};
										data_write = 4'b1100;
									end
								endcase	
							end
						endcase
						state = read_instr;
					end

					7'b1100011: begin						
						flag = 0;
						case (funct3) 
							3'b000: flag = (regis[rs1] == regis[rs2]) ? 1 : 0;
							3'b001: flag = (regis[rs1] != regis[rs2]) ? 1 : 0;
							3'b100: flag = ($signed(regis[rs1]) < $signed(regis[rs2])) ? 1 : 0;
							3'b101: flag = ($signed(regis[rs1]) >= $signed(regis[rs2])) ? 1 : 0;
							3'b110: flag = ($unsigned(regis[rs1]) < $unsigned(regis[rs2])) ? 1 : 0;
							3'b111: flag = ($unsigned(regis[rs1]) >= $unsigned(regis[rs2])) ? 1 : 0;
						endcase

						if (flag) 
							pc = pc + imm_b;
						else 
							pc = pc + 4;

						set_pc = 1;
						state = read_instr;
					end

					7'b0010111: begin
						regis[rd] = pc + imm_u;
						state = read_instr;
					end

					7'b0110111: begin
						regis[rd] = imm_u;
						state = read_instr;
					end

					7'b1101111: begin
						regis[rd] = pc + 4;
						pc = pc + imm_j;
						state = read_instr;
						set_pc = 1;
					end

				endcase	
				
				if (!set_pc)
					pc = pc + 4;
				
				instr_addr = pc;
				instr_read = 1;
			end

			memory: begin
				case (funct3)
					3'b010: regis[rd] = data_out;
					3'b000: regis[rd] = $signed({{24{data_out[7]}}, data_out[7:0]});
					3'b001: regis[rd] = $signed({{16{data_out[15]}}, data_out[15:0]});
					3'b100: regis[rd] = $unsigned({24'd0, data_out[7:0]});
					3'b101: regis[rd] = $unsigned({16'd0, data_out[15:0]});
				endcase

				if (data_read)
					data_read = 0;
				else
					state = read_instr;
			end
		endcase
	end
end

endmodule
