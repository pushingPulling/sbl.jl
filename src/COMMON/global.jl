#=
global:
- Julia version: 
- Author: Dan
- Date: 2021-06-02
=#
#not the same implementation as in C++BALL

export
	Byte, Position, Handle, Size, Distance, Index, ASCII, Amino_Acids,
	BALL_QSAR_RINGPERCEEPTIONPROCESSOR_RUN_COUNT,
	BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS,
	BALL_HALF_OF_MAX_RING_SIZE, BALL_Properties


const BALL_SIZE_TYPE = Int64
const BALL_INDEX_TYPE = Int64


const Byte = UInt8
const Position = BALL_SIZE_TYPE
const Handle = BALL_SIZE_TYPE
#const Size = BALL_SIZE_TYPE
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
		#whenever one tries to convert an ascii to any type, it will actually convert to a character
		Base.convert(::Type{Any}, x::ASCII) = convert(Char, x)


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

#const INVALID_Size = typemax(Size)
#const Size_MIN = 0;
#const Size_MAX = typemax(Size) - 1;

const Amino_Acids = String["ALA", "CYS", "ASP", "GLU", "PHE", "GLY", "HIS", "ILE", "LYS", "LEU",
 							"MET", "ASN", "PRO", "GLN", "ARG", "SER", "THR", "VAL", "TRP", "TYR"]
BALL_QSAR_RINGPERCEEPTIONPROCESSOR_RUN_COUNT = 1
BALL_QSAR_RINGPERCEEPTIONPROCESSOR_MAX_RUNS = 20
BALL_Properties = String["amino_acid", "InRing"]
const BALL_HALF_OF_MAX_RING_SIZE = 20		#Only detect Rings in SSSR with maximally 2*BALL_HALF_OF_MAX_RING_SIZE atoms