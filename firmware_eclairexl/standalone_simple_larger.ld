
/* Memory Definitions for a ZPU program running either from external RAM (up to 8 meg).
   or from unremapped Boot ROM / Stack RAM. */

MEMORY
{
  CODE (rx) : ORIGIN = 0x00000000, LENGTH = 0x0a000 /* 40k */
  RAM (rx) : ORIGIN = 0x0000e000, LENGTH = 0x01000 /* 8k */
}


/* Section Definitions */

SECTIONS
{
  /* first section is .fixed_vectors which is used for startup code */
  . = 0x0000000;
  .fixed_vectors :
  {
    *(.fixed_vectors)
  }>CODE

  /* Remaining code sections */
  . = ALIGN(4);
  .text :
  {
    *(.text)                   /* remaining code */
  } >CODE

  /* .rodata section which is used for read-only data (constants) */
  . = ALIGN(4);
  .rodata :
  {
    *(.rodata)
  } >CODE
  . = ALIGN(4);

  /* .data section which is used for initialized data. */
  . = ALIGN(4);
  .data :
  {
    _data = . ;
    *(.data)
    SORT(CONSTRUCTORS)
    . = ALIGN(4);
  } >CODE
  _romend = . ;

  /* .bss section which is used for uninitialized data */
  . = ALIGN(4);
  .bss :
  {
    __bss_start = . ;
    __bss_start__ = . ;
    *(.bss)
    *(COMMON)
  } >RAM
  __bss_end__ = . ;
}
