#=
global:
- Julia version: 
- Author: Dan
- Date: 2021-06-02
=#
#not the same implementation as in C++BALL
const BALL_SIZE_TYPE = Int64
const BALL_INDEX_TYPE = Int64


const Byte = UInt8
const Position = BALL_SIZE_TYPE
const Handle = BALL_SIZE_TYPE
const Size = BALL_SIZE_TYPE
const Distance = BALL_INDEX_TYPE
const Index = BALL_INDEX_TYPE

#this being an enum on one hand makes sence, because we want to store this info in bytes (UInt8s)
#but it also doesnt because we want it to be interpreted as a Char - requiring to convert it every time youw ant to use it
@enum ASCII begin

		ASCII__BACKSPACE        = convert(UInt8,'\b')
		ASCII__BELL             = convert(UInt8,'\a')
		ASCII__CARRIAGE_RETURN  = convert(UInt8,'\r')
		ASCII__HORIZONTAL_TAB   = convert(UInt8,'\t')
		ASCII__NEWLINE          = convert(UInt8,'\n')
		ASCII__SPACE            = convert(UInt8,' ')
		ASCII__VERTICAL_TAB     = convert(UInt8,'\v')

		ASCII__COLON            = convert(UInt8,':')
		ASCII__COMMA            = convert(UInt8,',')
		ASCII__EXCLAMATION_MARK = convert(UInt8,'!')
		ASCII__POINT            = convert(UInt8,'.')
		ASCII__QUESTION_MARK    = convert(UInt8,'?')
		ASCII__SEMICOLON        = convert(UInt8,';')
	end
		ASCII__RETURN           = ASCII__NEWLINE
		ASCII__TAB              = ASCII__HORIZONTAL_TAB
		Base.convert(::Type{Any}, x::ASCII) = convert(Char, x)	#whenever one tries to convert this it will be converted into a char automatically

const INVALID_Distance = typemax(Distance)
const Distance_MIN = typemin(Distance) + 1
const Distance_MAX = typemax(Distance)

const INVALID_Handle = typemax(Handle)
const Handle_MIN = 0 ;
const Handle_MAX = typemax(Handle) - 1

const INVALID_Index = -1;
const Index_MIN = 0;
const Index_MAX = typemax(BALL_INDEX_TYPE)

const INVALID_Position = typemax(Position)
const Position_MIN = 0
const Position_MAX = typemax(BALL_INDEX_TYPE) - 1

const INVALID_Size = typemax(Size)
const Size_MIN = 0;
const Size_MAX = typemax(Size) - 1;
