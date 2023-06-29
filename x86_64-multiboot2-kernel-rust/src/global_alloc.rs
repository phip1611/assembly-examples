use simple_chunk_allocator::{GlobalChunkAllocator, heap, heap_bitmap, PageAligned};

static mut HEAP: PageAligned<[u8; 4096]> = heap!(chunks=16, chunksize=256);

static mut HEAP_BITMAP: PageAligned<[u8; 2]> = heap_bitmap!(chunks=16);

#[global_allocator]
static ALLOCATOR: GlobalChunkAllocator =
    unsafe { GlobalChunkAllocator::new(HEAP.deref_mut_const(), HEAP_BITMAP.deref_mut_const()) };
