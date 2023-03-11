`timescale 1ns / 1ps

module top(
    input wire CS,
    input wire PHI2,
    inout RWB,
    output RDY,
    inout [15:0] addr,
    inout [7:0] data    
    );
    
    reg TXEN;
    reg WRITE;
    reg WAIT;
    wire [4:0] regaddr;
    reg [7:0] dbyte;
    reg [15:0] sadd;
    reg [15:0] sinc;
    reg [15:0] dadd;
    reg [15:0] dinc;
    reg [15:0] count;
    reg [7:0] tmpdata;
    reg [15:0] tmpaddr;
        
    initial begin
        TXEN = 0;
        WRITE = 0;
        WAIT = 1;
    end
        
     
    always @(posedge PHI2) begin
            
        if(TXEN == 1) begin
            if(count > 0) begin
                if(WRITE) begin
                    if(WAIT) begin
                        tmpaddr = dadd;
                        tmpdata <= dbyte;
                        dadd <= dadd + dinc;
                        WAIT <= 0;
                    end
                    else begin                    
                        count <= count - 1;
                        WRITE <= 0;
                        WAIT <= 1;                               
                    end
                end
                else begin
                    if(WAIT) begin
                        tmpaddr = sadd;
                        sadd <= sadd + sinc;
                        WAIT <= 0;
                    end
                    else begin
                        dbyte <= data;
                        WAIT <= 1;
                        WRITE <= 1;                                        
                    end 
                end
            end 
            else begin
                TXEN <= 0;
                WRITE <= 0;
            end            
        end
        else begin
            if(CS == 1) begin            
                if(RWB == 1) begin
                    WRITE <= 0;
                    case(regaddr)
                        5'b00000 : sadd[7:0] <= data;
                        5'b00001 : sadd[15:8] <= data;
                        5'b00010 : sinc[7:0] <= data;
                        5'b00011 : sinc[15:8] <= data;
                        5'b00100 : dadd[7:0] <= data;
                        5'b00101 : dadd[15:8] <= data;
                        5'b00110 : dinc[7:0] <= data;
                        5'b00111 : dinc[15:8] <= data;
                        5'b01000 : begin
                                count[7:0] = data;
                                if(count > 0) begin
                                    WAIT <= 1;
                                    TXEN <= 1;         
                                end                                                                       
                                end
                        5'b01001 : count[15:8] <= data;
                        default: TXEN <= 0;         
                    endcase         
                end
                else begin
                    WRITE <= 1;
                    tmpdata <= 0;            
                end
            end            
            else begin
                WRITE <= 0;
                TXEN <= 0;
            end        
        end                  
    end
    
    assign regaddr = addr[4:0];
    assign RWB = TXEN ? WRITE : 1'bZ;
    assign RDY = TXEN ? 1'b0 : 1'bZ;
    assign data = WRITE ? tmpdata : 8'bZ;
    assign addr = TXEN ? tmpaddr : 16'bZ;
    
endmodule
