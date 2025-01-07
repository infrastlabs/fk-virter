package virter

import (
	"fmt"
	"runtime"
	"strings"

	lx "github.com/libvirt/libvirt-go-xml"
)

type CpuArch string

const (
	CpuArchAMD64   = CpuArch("amd64")
	CpuArchARM64   = CpuArch("arm64")
	CpuArchPPC64LE = CpuArch("ppc64le")
	CpuArchS390x   = CpuArch("s390x")
	CpuArchNative  = CpuArch(runtime.GOARCH)
)

func (c *CpuArch) String() string {
	arch := c.get()
	return string(arch)
}

func (c *CpuArch) Set(s string) error {
	switch CpuArch(strings.ToLower(s)) {
	case CpuArchAMD64:
		*c = CpuArchAMD64
	case CpuArchARM64:
		*c = CpuArchARM64
	case CpuArchPPC64LE:
		*c = CpuArchPPC64LE
	case CpuArchS390x:
		*c = CpuArchS390x
	case "":
		*c = CpuArchNative
	default:
		return unknownArch(s)
	}

	return nil
}

func (c *CpuArch) Type() string {
	return "arch"
}

type unknownArch string

func (u unknownArch) Error() string {
	return fmt.Sprintf("unknown arch '%s', supported are: %+v", string(u), []CpuArch{CpuArchAMD64, CpuArchARM64, CpuArchPPC64LE})
}

func (c *CpuArch) DomainType() string {
	arch := c.get()

	if arch == CpuArchNative {
		return "kvm"
	}

	return "qemu"
}

func (c *CpuArch) QemuArch() string {
	arch := c.get()

	switch arch {
	case CpuArchAMD64:
		return "x86_64"
	case CpuArchARM64:
		return "aarch64"
	case CpuArchPPC64LE:
		return "ppc64"
	case CpuArchS390x:
		return "s390x"
	default:
		return ""
	}
}

func (c *CpuArch) OSDomain() *lx.DomainOS {
	return &lx.DomainOS{
		Type: &lx.DomainOSType{
			Arch:    c.QemuArch(),
			Type:    "hvm",
			Machine: c.Machine(),
		},
		Firmware:    c.Firmware(),
		BootDevices: []lx.DomainBootDevice{{Dev: "hd"}},
	}
}

func (c *CpuArch) Firmware() string {
	arch := c.get()

	switch arch {
	case CpuArchARM64:
		return "efi"
	default:
		return ""
	}
}

func (c *CpuArch) CPU() *lx.DomainCPU {
	arch := c.get()

	/* if arch == CpuArchNative {
		return &lx.DomainCPU{
			Mode: "host-model", // CPU mode 'host-model' for aarch64 kvm domain on aarch64 host is not supported by hypervisor
		}
	} */

	switch arch {
	case CpuArchAMD64:
		if arch == CpuArchNative {
			return &lx.DomainCPU{
				Mode: "host-model", // x64: cp upper
			}
		}
		return &lx.DomainCPU{
			Mode:  "custom",
			Match: "exact",
			Model: &lx.DomainCPUModel{
				Value:    "max", //could not create (start) domain: internal error: Unknown CPU model max
				Fallback: "forbid",
			},
		}
	case CpuArchARM64:
		if arch == CpuArchNative {
			return &lx.DomainCPU{
				Mode: "host-passthrough", // arm64: cp upper
			}
		}
		// kvm_init_vcpu: kvm_arch_init_vcpu failed (0): Invalid argument; >> <cpu mode='host-passthrough' check='none'/>
		return &lx.DomainCPU{
			Mode:  "custom",
			Match: "exact",
			Model: &lx.DomainCPUModel{
				// Value:    "cortex-a72",
				// unsupported configuration: CPU model cortex-a55 is not supported by hypervisor
				// Value:    "cortex-a55", //lscpu: Model name:            Cortex-A55
				Value:    "cortex-a57", 
				Fallback: "forbid",
			},
		}
	case CpuArchPPC64LE:
		return &lx.DomainCPU{
			Mode:  "custom",
			Match: "exact",
			Model: &lx.DomainCPUModel{
				Value:    "power10",
				Fallback: "forbid",
			},
		}
	case CpuArchS390x:
		return &lx.DomainCPU{
			Mode:  "custom",
			Match: "exact",
			Model: &lx.DomainCPUModel{
				Value:    "max",
				Fallback: "forbid",
			},
		}
	default:
		return nil
	}
}

func (c *CpuArch) Machine() string {
	switch c.get() {
	case CpuArchAMD64:
		// return "q35"
		return "pc"
	case CpuArchARM64:
		return "virt"
	case CpuArchPPC64LE:
		return "pseries"
	case CpuArchS390x:
		return "s390-ccw-virtio"
	default:
		return ""
	}
}

func (c *CpuArch) PM() *lx.DomainPM {
	arch := c.get()

	switch arch {
	case CpuArchAMD64:
		return &lx.DomainPM{
			SuspendToDisk: &lx.DomainPMPolicy{Enabled: "no"},
			SuspendToMem:  &lx.DomainPMPolicy{Enabled: "no"},
		}
	default:
		return nil
	}
}

func (c *CpuArch) get() CpuArch {
	if c == nil || *c == "" {
		return CpuArchNative
	}

	return *c
}
